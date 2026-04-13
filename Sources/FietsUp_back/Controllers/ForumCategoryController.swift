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
    
    let request = routes.grouped("forum", "categories")
    
    let userProtected = request
      .grouped(JWTMiddleware())
      .groupedOpenAPI(auth: .bearer(id: "BearerAuth", format: "JWT"))
    
    let adminProtected = request
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
    
    adminProtected.patch(":forumCategoryID", use: self.patchByID)
      .openAPI(
        tags: "Admin", "Forum", "Categories",
        summary: "Patch",
        description: "Find and patch an existing forum category by id",
        path: .type(UUID.self),
        body: .type(PatchForumCategoryDTO.self),
        response: .type(GetForumCategoryDTO.self)
      )
    
    adminProtected.delete(":forumCategoryID", use: self.deleteByID)
      .openAPI(
        tags: "Admin", "Forum", "Categories",
        summary: "Delete",
        description: "Permanently delete an existing forum category by id",
        path: .type(UUID.self),
        response: .type(HTTPStatus.self)
      )
  }
  
  @Sendable
  func getAll(req: Request) async throws -> Response {
    let user = try await req.requireUser()
    
    // TODO: split that into different routes
    if user.adminRights >= 2 {
      let categories = try await ForumCategory.query(on: req.db)
        .sort(\.$name)
        .all()
        .map { try GetForumCategoryDTO(from: $0) }
      return try await categories.encodeResponse(for: req)
    } else {
      let categories = try await ForumCategory.query(on: req.db)
        .sort(\.$lastActivityDate, .descending)
        .all()
      
      let countsByCategoryID = try await postCounts(for: categories, on: req.db)
      
      let dtos = try categories.map { category in
        try GetForumCategoryWithCountsDTO(from: category, totalPosts: countsByCategoryID[category.requireID()] ?? 0)
      }
      return try await dtos.encodeResponse(for: req)
    }
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
  func patchByID(req: Request) async throws -> GetForumCategoryDTO {
    let id = try req.parameters.require("forumCategoryID", as: UUID.self)
    let category = try await findCategory(id: id, on: req.db)
    
    try PatchForumCategoryDTO.validate(content: req)
    let dto = try req.content.decode(PatchForumCategoryDTO.self)
    category.patch(with: dto)
    try await category.save(on: req.db)
    return try GetForumCategoryDTO(from: category)
  }
  
  @Sendable
  func deleteByID(req: Request) async throws -> HTTPStatus {
    let id = try req.parameters.require("forumCategoryID", as: UUID.self)
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
  
  private func postCounts(for categories: [ForumCategory], on db: any Database) async throws -> [UUID: Int] {
    guard let sql = db as? any SQLDatabase else { throw Abort(.internalServerError) }
    
    let idList = try categories
      .map { "UNHEX('\(try $0.requireID().hexString)')" }
      .joined(separator: ", ")
    
    let rows = try await sql.raw("""
        SELECT HEX(id_forum_category) as id_forum_category, COUNT(*) as total_posts
        FROM \(unsafeRaw: ForumPost.schema)
        WHERE id_forum_category IN (\(unsafeRaw: idList))
        GROUP BY id_forum_category
        """).all()
    
    return try Dictionary(uniqueKeysWithValues: rows.map {
      let hex = try $0.decode(column: "id_forum_category", as: String.self)
      guard let uuid = UUID(hex: hex) else { throw Abort(.internalServerError) }
      return (uuid, try $0.decode(column: "total_posts", as: Int.self))
    })
  }
}
