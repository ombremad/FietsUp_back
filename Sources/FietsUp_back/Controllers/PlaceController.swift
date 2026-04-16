//
//  PlaceController.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 25/03/2026.
//

import Vapor
import Fluent

struct PlaceController: RouteCollection {
  func boot(routes: any RoutesBuilder) throws {
    
    let request = routes.grouped("places")
    
    let adminProtected = request
      .grouped(JWTMiddleware(), RequireAdminLevelMiddleware(minimumLevel: 2))
      .groupedOpenAPI(auth: .bearer(id: "AdminBearer", format: "JWT"))
    
    adminProtected.post(use: self.create)
      .openAPI(
        tags: "Places",
        summary: "Create",
        description: "Create a place",
        body: .type(CreatePlaceDTO.self),
        response: .type(GetPlaceDTO.self)
      )
    
    adminProtected.get(use: self.getAll)
      .openAPI(
        tags: "Places",
        summary: "List",
        description: "List all available places",
        response: .type([GetPlaceDTO].self)
      )
    
    adminProtected.patch(":placeID", use: self.patchByID)
      .openAPI(
        tags: "Places",
        summary: "Patch",
        description: "Find and patch an existing place by id",
        path: .type(UUID.self),
        body: .type(PatchPlaceDTO.self),
        response: .type(GetPlaceDTO.self)
      )
    
    adminProtected.delete(":placeID", use: self.deleteByID)
      .openAPI(
        tags: "Places",
        summary: "Delete",
        description: "Permanently delete an existing place by id",
        path: .type(UUID.self),
        response: .type(HTTPStatus.self)
      )
    
    // TODO: get userProtected closest places
  }

  @Sendable
  func create(req: Request) async throws -> GetPlaceDTO {
    try CreatePlaceDTO.validate(content: req)
    let dto = try req.content.decode(CreatePlaceDTO.self)
    
    let place = Place(from: dto)
    try await place.save(on: req.db)
    
    let categories = try await PlaceCategory.query(on: req.db)
      .filter(\.$id ~~ dto.categoriesIds)
      .all()
    try await place.$categories.attach(categories, on: req.db)
    try await place.$categories.load(on: req.db)
    return try GetPlaceDTO(from: place)
  }
  
  @Sendable
  func getAll(req: Request) async throws -> [GetPlaceDTO] {
    try await Place.query(on: req.db)
      .sort(\.$name)
      .limit(50)
      .with(\.$categories)
      .all()
      .map { place in try GetPlaceDTO(from: place) }
  }
  
  @Sendable
  func patchByID(req: Request) async throws -> GetPlaceDTO {
    let id = try req.parameters.require("placeID", as: UUID.self)
    let place = try await find(id: id, on: req.db)
    
    try PatchPlaceDTO.validate(content: req)
    let dto = try req.content.decode(PatchPlaceDTO.self)
    place.patch(with: dto)
    try await place.save(on: req.db)
    return try GetPlaceDTO(from: place)
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
      .first()
    return try returnOrFail(place)
  }

}
