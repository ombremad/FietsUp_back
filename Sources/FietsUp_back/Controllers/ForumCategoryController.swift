//
//  ForumCategoryController.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 26/03/2026.
//

import Vapor
import Fluent
import SQLKit

struct ForumCategoryController: RouteCollection {
  func boot(routes: any RoutesBuilder) throws {
    
    let userProtected =
    routes.grouped("forum", "categories")
      .grouped(JWTMiddleware())
      .groupedOpenAPI(auth: .bearer(id: "BearerAuth", format: "JWT"))

    let adminProtected =
    routes.grouped("admin", "forum", "categories")
        .grouped(JWTMiddleware(), RequireAdminLevelMiddleware(minimumLevel: 2))
        .groupedOpenAPI(auth: .bearer(id: "AdminBearer", format: "JWT"))
    
    userProtected.get(use: self.getAll)
      .openAPI(
        tags: "Forum", "Categories",
        summary: "List",
        description: "List forum categories",
        response: .type([GetForumCategoryWithCountsDTO].self)
      )
    
    adminProtected.post(use: self.create)
      .openAPI(
        tags: "Admin", "Forum", "Categories",
        summary: "Create",
        description: "Create a forum category",
        body: .type(CreateForumCategoryDTO.self),
        response: .type(GetForumCategoryDTO.self)
      )
    
    adminProtected.get(use: self.getAllAdmin)
      .openAPI(
        tags: "Admin", "Forum", "Categories",
        summary: "List",
        description: "List all available forum categories",
        response: .type([GetForumCategoryDTO].self)
      )
    
    adminProtected.patch(":id", use: self.patchById)
      .openAPI(
        tags: "Admin", "Forum", "Categories",
        summary: "Patch",
        description: "Find and patch an existing forum category by id",
        path: .type(UUID.self),
        body: .type(PatchForumCategoryDTO.self),
        response: .type(GetForumCategoryDTO.self)
      )
    
    adminProtected.delete(":id", use: self.deleteById)
      .openAPI(
        tags: "Admin", "Forum", "Categories",
        summary: "Delete",
        description: "Permanently delete an existing forum category by id",
        path: .type(UUID.self),
        response: .type(HTTPStatus.self)
      )
  }
  
  // User
  
  @Sendable
  func getAll(req: Request) async throws -> [GetForumCategoryWithCountsDTO] {
    try await ForumCategoryWithCounts.query(on: req.db)
      .sort(\.$lastActivityDate, .descending)
      .all()
      .map { category in try GetForumCategoryWithCountsDTO(from: category) }
  }
  
  @Sendable
  func create(req: Request) async throws -> GetForumCategoryDTO {
    try CreateForumCategoryDTO.validate(content: req)
    let dto = try req.content.decode(CreateForumCategoryDTO.self)
    
    let forumCategory = ForumCategory(from: dto)
    try await forumCategory.save(on: req.db)
    return try GetForumCategoryDTO(from: forumCategory)
  }
    
  // Admin
  
  @Sendable
  func getAllAdmin(req: Request) async throws -> [GetForumCategoryDTO] {
    try await ForumCategory.query(on: req.db)
      .sort(\.$name)
      .all()
      .map { category in try GetForumCategoryDTO(from: category) }
  }
  
  @Sendable
  func patchById(req: Request) async throws -> GetForumCategoryDTO {
    let id = try req.parameters.require("id", as: UUID.self)
    let category = try await findCategory(id: id, on: req.db)
    
    try PatchForumCategoryDTO.validate(content: req)
    let dto = try req.content.decode(PatchForumCategoryDTO.self)
    category.patch(with: dto)
    try await category.save(on: req.db)
    return try GetForumCategoryDTO(from: category)
  }
  
  @Sendable
  func deleteById(req: Request) async throws -> HTTPStatus {
    let id = try req.parameters.require("id", as: UUID.self)
    let category = try await findCategory(id: id, on: req.db)
    
    try await category.delete(on: req.db)
    return .noContent
  }
    
  private func findCategory(id: UUID, on db: any Database) async throws -> ForumCategory {
    let query = try await ForumCategory.query(on: db)
        .filter(\.$id == id)
        .first()
    return try returnOrFail(query)
  }
}
