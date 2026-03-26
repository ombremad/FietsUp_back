//
//  ModerationCategoryController.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 26/03/2026.
//

import Vapor
import Fluent

struct ModerationCategoryController: RouteCollection {
  func boot(routes: any RoutesBuilder) throws {
    
    let request = routes.grouped("moderation", "categories")
    let adminProtected =
    request
      .grouped(JWTMiddleware(), RequireAdminLevelMiddleware(minimumLevel: 2))
      .groupedOpenAPI(auth: .bearer(id: "AdminBearer", format: "JWT"))
    
    adminProtected.post(use: self.create)
      .openAPI(
        tags: "Moderation", "Categories",
        summary: "Create",
        description: "Create a moderation category",
        body: .type(CreateModerationCategoryDTO.self),
        response: .type(GetModerationCategoryDTO.self)
      )
    
    adminProtected.get(use: self.getAll)
      .openAPI(
        tags: "Moderation", "Categories",
        summary: "List",
        description: "List all available moderation categories",
        response: .type([GetModerationCategoryDTO].self)
      )
    
    adminProtected.patch(":id", use: self.patchById)
      .openAPI(
        tags: "Moderation", "Categories",
        summary: "Patch",
        description: "Find and patch an existing moderation category by id",
        path: .type(UUID.self),
        body: .type(PatchModerationCategoryDTO.self),
        response: .type(GetModerationCategoryDTO.self)
      )
  }
  
  @Sendable
  func create(req: Request) async throws -> GetModerationCategoryDTO {
    try CreateModerationCategoryDTO.validate(content: req)
    let dto = try req.content.decode(CreateModerationCategoryDTO.self)
    
    let moderationCategory = ModerationCategory(from: dto)
    try await moderationCategory.save(on: req.db)
    return try GetModerationCategoryDTO(from: moderationCategory)
  }
  
  @Sendable
  func getAll(req: Request) async throws -> [GetModerationCategoryDTO] {
    try await ModerationCategory.query(on: req.db)
      .sort(\.$name)
      .all()
      .map { category in try GetModerationCategoryDTO(from: category) }
  }
  
  @Sendable
  func patchById(req: Request) async throws -> GetModerationCategoryDTO {
    let id = try req.parameters.require("id", as: UUID.self)
    let category = try await find(id: id, on: req.db)
    
    try PatchModerationCategoryDTO.validate(content: req)
    let dto = try req.content.decode(PatchModerationCategoryDTO.self)
    category.patch(with: dto)
    try await category.save(on: req.db)
    return try GetModerationCategoryDTO(from: category)
  }
    
  private func find(id: UUID, on db: any Database) async throws -> ModerationCategory {
    guard
      let category = try await ModerationCategory.query(on: db)
        .filter(\.$id == id)
        .first()
    else {
      throw Abort(.notFound)
    }
    return category
  }
}
