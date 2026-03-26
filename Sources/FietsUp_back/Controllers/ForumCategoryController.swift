//
//  ForumCategoryController.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 26/03/2026.
//

import Vapor
import Fluent

struct ForumCategoryController: RouteCollection {
  func boot(routes: any RoutesBuilder) throws {
    
    let request = routes.grouped("forum", "categories")
    let adminProtected =
      request
        .grouped(JWTMiddleware(), RequireAdminLevelMiddleware(minimumLevel: 2))
        .groupedOpenAPI(auth: .bearer(id: "AdminBearer", format: "JWT"))
    
    adminProtected.post(use: self.create)
      .openAPI(
        tags: "Forum", "Categories",
        summary: "Create",
        description: "Create a forum category",
        body: .type(CreateForumCategoryDTO.self),
        response: .type(GetForumCategoryDTO.self)
      )
    
    adminProtected.get(use: self.getAll)
      .openAPI(
        tags: "Forum", "Categories",
        summary: "List",
        description: "List all available forum categories",
        response: .type([GetForumCategoryDTO].self)
      )
    
    adminProtected.patch(":id", use: self.patchById)
      .openAPI(
        tags: "Forum", "Categories",
        summary: "Patch",
        description: "Find and patch an existing forum category by id",
        path: .type(UUID.self),
        body: .type(PatchForumCategoryDTO.self),
        response: .type(GetForumCategoryDTO.self)
      )
    
    adminProtected.delete(":id", use: self.deleteById)
      .openAPI(
        tags: "Forum", "Categories",
        summary: "Delete",
        description: "Permanently delete an existing forum category by id",
        path: .type(UUID.self),
        response: .type(HTTPStatus.self)
      )
  }
  
  @Sendable
  func create(req: Request) async throws -> GetForumCategoryDTO {
    try CreateForumCategoryDTO.validate(content: req)
    let dto = try req.content.decode(CreateForumCategoryDTO.self)
    
    let forumCategory = ForumCategory(from: dto)
    try await forumCategory.save(on: req.db)
    return try GetForumCategoryDTO(from: forumCategory)
  }
  
  @Sendable
  func getAll(req: Request) async throws -> [GetForumCategoryDTO] {
    try await ForumCategory.query(on: req.db)
      .sort(\.$name)
      .all()
      .map { category in try GetForumCategoryDTO(from: category) }
  }
  
  @Sendable
  func patchById(req: Request) async throws -> GetForumCategoryDTO {
    let id = try req.parameters.require("id", as: UUID.self)
    let category = try await find(id: id, on: req.db)
    
    try PatchForumCategoryDTO.validate(content: req)
    let dto = try req.content.decode(PatchForumCategoryDTO.self)
    category.patch(with: dto)
    try await category.save(on: req.db)
    return try GetForumCategoryDTO(from: category)
  }
  
  @Sendable
  func deleteById(req: Request) async throws -> HTTPStatus {
    let id = try req.parameters.require("id", as: UUID.self)
    let category = try await find(id: id, on: req.db)
    
    try await category.delete(on: req.db)
    return .noContent
  }
  
  private func find(id: UUID, on db: any Database) async throws -> ForumCategory {
    guard
      let category = try await ForumCategory.query(on: db)
        .filter(\.$id == id)
        .first()
    else {
      throw Abort(.notFound)
    }
    return category
  }
}
