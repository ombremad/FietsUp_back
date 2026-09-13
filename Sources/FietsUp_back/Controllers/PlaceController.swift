//
//  PlaceController.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 25/03/2026.
//

import Vapor
import Fluent
import FluentSQL

struct PlaceController: RouteCollection {
  func boot(routes: any RoutesBuilder) throws {
    
    let request = routes.grouped("places")
    
    let userProtected = request
      .grouped(JWTMiddleware())
      .groupedOpenAPI(auth: .bearer(id: "BearerAuth", format: "JWT"))
    
    let adminProtected = request
      .grouped(JWTMiddleware(), RequireAdminLevelMiddleware(minimumLevel: 2))
      .groupedOpenAPI(auth: .bearer(id: "AdminBearer", format: "JWT"))
    
    adminProtected.post(use: self.create)
      .openAPI(
        tags: "Places",
        summary: "Create",
        description: "Create a place",
        body: .type(CreatePlaceDTO.self),
        response: .type(GetPlaceWithRatingDTO.self)
      )
    
    userProtected.post(":placeID", "rating", use: self.rate)
      .openAPI(
        tags: "Places",
        summary: "Rate",
        description: "Rate a place",
        path: .type(UUID.self),
        body: .type(CreateOrPatchRatingDTO.self),
        response: .type(GetPlaceWithRatingDTO.self)
      )
    
    userProtected.get("near", use: self.getNearest)
      .openAPI(
        tags: "Places",
        summary: "Near",
        description: "Get nearest places sorted",
        query: .type(QueryPlaceDTO.self),
        response: .type([GetPlaceWithRatingDTO].self)
      )
    
    adminProtected.get(use: self.getAll)
      .openAPI(
        tags: "Places",
        summary: "List",
        description: "List all available places",
        query: .type(QueryPageDTO.self),
        response: .type(Page<GetPlaceWithRatingDTO>.self)
      )
    
    adminProtected.patch(":placeID", use: self.patchByID)
      .openAPI(
        tags: "Places",
        summary: "Patch",
        description: "Find and patch an existing place by id",
        path: .type(UUID.self),
        body: .type(PatchPlaceDTO.self),
        response: .type(GetPlaceWithRatingDTO.self)
      )
    
    adminProtected.delete(":placeID", use: self.deleteByID)
      .openAPI(
        tags: "Places",
        summary: "Delete",
        description: "Permanently delete an existing place by id",
        path: .type(UUID.self),
        response: .type(HTTPStatus.self)
      )
  }

  @Sendable
  func create(req: Request) async throws -> GetPlaceWithRatingDTO {
    try CreatePlaceDTO.validate(content: req)
    let dto = try req.content.decode(CreatePlaceDTO.self)
    
    let place = Place(from: dto)
    try await place.save(on: req.db)
    
    let categories = try await PlaceCategory.query(on: req.db)
      .filter(\.$id ~~ dto.categoriesIds)
      .all()
    try await place.$categories.attach(categories, on: req.db)
    try await place.$categories.load(on: req.db)
    try await place.$ratings.load(on: req.db)
    return try GetPlaceWithRatingDTO(from: place)
  }
  
  @Sendable
  func rate(req: Request) async throws -> GetPlaceWithRatingDTO {
    let userID = try req.requireUser().requireID()
    let placeID = try req.parameters.require("placeID", as: UUID.self)
    
    guard try await Place.query(on: req.db)
      .filter(\.$id == placeID)
      .first() != nil
    else {
      throw Abort(.notFound)
    }
    
    try CreateOrPatchRatingDTO.validate(content: req)
    let dto = try req.content.decode(CreateOrPatchRatingDTO.self)
    
    if let existing = try await Rating.query(on: req.db)
      .filter(\.$user.$id == userID)
      .filter(\.$place.$id == placeID)
      .first()
    {
      existing.update(with: dto)
      try await existing.save(on: req.db)
    } else {
      let rating = Rating(from: dto, userID: userID, placeID: placeID)
      try await rating.save(on: req.db)
    }
    
    let place = try await find(id: placeID, on: req.db)
    return try GetPlaceWithRatingDTO(from: place)
  }
  
  @Sendable
  func getNearest(req: Request) async throws -> [GetPlaceWithRatingDTO] {
    try QueryPlaceDTO.validate(query: req)
    let query = try req.query.decode(QueryPlaceDTO.self)
    let radius = 50_000
    let limit = 50

    guard let sql = req.db as? (any SQLDatabase) else {
      throw Abort(.internalServerError)
    }
    
    struct NearbyResult: Decodable { let id: UUID }
    
    let orderedIds = try await sql.raw("""
    SELECT p.id FROM (
        SELECT id,
            ST_Distance_Sphere(
                location,
                ST_GeomFromText(
                    CONCAT('POINT(', \(bind: query.longitude), ' ', \(bind: query.latitude), ')'),
                    4326
                )
            ) AS distance
        FROM places
    ) AS p
    WHERE p.distance <= \(bind: radius)
    ORDER BY p.distance
    LIMIT \(bind: limit)
    """).all(decoding: NearbyResult.self).map(\.id)

    guard !orderedIds.isEmpty else { return [] }
    
    let places = try await Place.query(on: req.db)
      .filter(\.$id ~~ orderedIds)
      .with(\.$categories)
      .with(\.$ratings)
      .all()
    
    return try orderedIds.compactMap { id in places.first { $0.id == id } }
      .map { try GetPlaceWithRatingDTO(from: $0) }
  }
  
  @Sendable
  func getAll(req: Request) async throws -> Page<GetPlaceWithRatingDTO> {
    try QueryPageDTO.validate(query: req)

    return try await Place.query(on: req.db)
      .sort(\.$name)
      .with(\.$categories)
      .with(\.$ratings)
      .paginate(for: req)
      .map { place in try GetPlaceWithRatingDTO(from: place) }
  }
  
  @Sendable
  func patchByID(req: Request) async throws -> GetPlaceWithRatingDTO {
    let id = try req.parameters.require("placeID", as: UUID.self)
    let place = try await find(id: id, on: req.db)
    
    try PatchPlaceDTO.validate(content: req)
    let dto = try req.content.decode(PatchPlaceDTO.self)
    place.patch(with: dto)
    try await place.save(on: req.db)
    
    if let categoriesIds = dto.categoriesIds {
      let categories = try await PlaceCategory.query(on: req.db)
        .filter(\.$id ~~ categoriesIds)
        .all()
      try await place.$categories.detachAll(on: req.db)
      try await place.$categories.attach(categories, on: req.db)
    }
    try await place.$categories.load(on: req.db)
    try await place.$ratings.load(on: req.db)

    return try GetPlaceWithRatingDTO(from: place)
  }
  
  @Sendable
  func deleteByID(req: Request) async throws -> HTTPStatus {
    let id = try req.parameters.require("placeID", as: UUID.self)
    let place = try await find(id: id, on: req.db)
    
    try await place.delete(on: req.db)
    return .noContent
  }
  
  private func find(id: UUID, on db: any Database) async throws -> Place {
    let place = try await Place.query(on: db)
      .filter(\.$id == id)
      .with(\.$categories)
      .with(\.$ratings)
      .first()
    return try returnOrFail(place)
  }
}
