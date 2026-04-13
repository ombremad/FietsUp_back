//
//  PlaceCategoryController.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 25/03/2026.
//

import Vapor
import Fluent

struct PlaceCategoryController: RouteCollection {
  func boot(routes: any RoutesBuilder) throws {
    
    let request = routes.grouped("places", "categories")
    
    let adminProtected = request
      .grouped(JWTMiddleware(), RequireAdminLevelMiddleware(minimumLevel: 2))
      .groupedOpenAPI(auth: .bearer(id: "AdminBearer", format: "JWT"))

    adminProtected.post(use: self.create)
      .openAPI(
        tags: "Places", "Categories",
        summary: "Create",
        description: "Create a place category",
        body: .type(CreatePlaceCategoryDTO.self),
        response: .type(GetPlaceCategoryDTO.self)
      )
    
    adminProtected.get(use: self.getAll)
      .openAPI(
        tags: "Places", "Categories",
        summary: "List",
        description: "List all available place categories",
        response: .type([GetPlaceCategoryDTO].self)
      )
    
    adminProtected.patch(":placeCategoryID", use: self.patchByID)
      .openAPI(
        tags: "Places", "Categories",
        summary: "Patch",
        description: "Find and patch an existing place category by id",
        path: .type(UUID.self),
        body: .type(PatchPlaceCategoryDTO.self),
        response: .type(GetPlaceCategoryDTO.self)
      )
    
    adminProtected.delete(":placeCategoryID", use: self.deleteByID)
      .openAPI(
        tags: "Places", "Categories",
        summary: "Delete",
        description: "Permanently delete an existing place category by id",
        path: .type(UUID.self),
        response: .type(HTTPStatus.self)
      )
  }
  
  @Sendable
  func create(req: Request) async throws -> GetPlaceCategoryDTO {
    try CreatePlaceCategoryDTO.validate(content: req)
    let dto = try req.content.decode(CreatePlaceCategoryDTO.self)
    
    let placeCategory = PlaceCategory(from: dto)
    try await placeCategory.save(on: req.db)
    return try GetPlaceCategoryDTO(from: placeCategory)
  }
  
  @Sendable
  func getAll(req: Request) async throws -> [GetPlaceCategoryDTO] {
    try await PlaceCategory.query(on: req.db)
      .sort(\.$name)
      .all()
      .map { category in try GetPlaceCategoryDTO(from: category) }
  }
  
  @Sendable
  func patchByID(req: Request) async throws -> GetPlaceCategoryDTO {
    let id = try req.parameters.require("placeCategoryID", as: UUID.self)
    let category = try await find(id: id, on: req.db)
    
    try PatchPlaceCategoryDTO.validate(content: req)
    let dto = try req.content.decode(PatchPlaceCategoryDTO.self)
    category.patch(with: dto)
    try await category.save(on: req.db)
    return try GetPlaceCategoryDTO(from: category)
  }
  
  @Sendable
  func deleteByID(req: Request) async throws -> HTTPStatus {
    let id = try req.parameters.require("placeCategoryID", as: UUID.self)
    let category = try await find(id: id, on: req.db)

    try await category.delete(on: req.db)
    return .noContent
  }
  
  private func find(id: UUID, on db: any Database) async throws -> PlaceCategory {
    guard
      let category = try await PlaceCategory.query(on: db)
        .filter(\.$id == id)
        .first()
    else {
      throw Abort(.notFound)
    }
    return category
  }
}
