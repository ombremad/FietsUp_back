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
    
    adminProtected.post("admin", use: self.create)
      .openAPI(
        tags: "Admin", "Forum", "Categories",
        summary: "Create",
        description: "Create a forum category",
        body: .type(CreateForumCategoryDTO.self),
        response: .type(GetForumCategoryDTO.self)
      )
    
    adminProtected.get("admin", use: self.getAll)
      .openAPI(
        tags: "Forum", "Categories",
        summary: "List",
        description: "List forum categories",
        response: .type([GetForumCategoryWithCountsDTO].self)
      )
    
    userProtected.get(use: self.getIndex)
      .openAPI(
        tags: "Forum", "Categories",
        summary: "Index",
        description: "Forum index",
        response: .type([GetForumCategoryWithCountsDTO].self)
      )
    
    userProtected.get(":forumCategoryID", use: self.getByID)
      .openAPI(
        tags: "Forum", "Categories",
        summary: "Get",
        description: "Find and get an existing category and its posts by id",
        response: .type(GetForumCategoryDTO.self)
      )
        
    adminProtected.patch("admin", ":forumCategoryID", use: self.patchByID)
      .openAPI(
        tags: "Admin", "Forum", "Categories",
        summary: "Patch",
        description: "Find and patch an existing forum category by id",
        path: .type(UUID.self),
        body: .type(PatchForumCategoryDTO.self),
        response: .type(GetForumCategoryDTO.self)
      )
    
    adminProtected.delete("admin", ":forumCategoryID", use: self.deleteByID)
      .openAPI(
        tags: "Admin", "Forum", "Categories",
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
    return try GetForumCategoryDTO(from: forumCategory, commentCounts: [:])
  }
  
  @Sendable
  func getAll(req: Request) async throws -> [GetForumCategoryWithCountsDTO] {
    let categories = try await ForumCategory.query(on: req.db)
      .sort(\.$name)
      .all()
    
    let countsByCategoryID = try await postCounts(for: categories, on: req.db)
    
    return try categories.map { category in
      try GetForumCategoryWithCountsDTO(from: category, totalPosts: countsByCategoryID[category.requireID()] ?? 0)
    }
  }
  
  @Sendable
  func getIndex(req: Request) async throws -> [GetForumCategoryWithCountsDTO] {
    let categories = try await ForumCategory.query(on: req.db)
      .sort(\.$lastActivityDate, .descending)
      .all()
    
    let countsByCategoryID = try await postCounts(for: categories, on: req.db)
    
    return try categories.map { category in
      try GetForumCategoryWithCountsDTO(from: category, totalPosts: countsByCategoryID[category.requireID()] ?? 0)
    }
  }
  
  @Sendable
  func getByID(req: Request) async throws -> GetForumCategoryDTO {
    let categoryID = try req.parameters.require("forumCategoryID", as: UUID.self)
    let category = try await findCategory(id: categoryID, on: req.db)
    let commentCounts = try await countForumComments(for: category.forumPosts, on: req.db)
    return try GetForumCategoryDTO(from: category, commentCounts: commentCounts)
  }
      
  @Sendable
  func patchByID(req: Request) async throws -> GetForumCategoryDTO {
    let id = try req.parameters.require("forumCategoryID", as: UUID.self)
    let category = try await findCategory(id: id, on: req.db)
    
    try PatchForumCategoryDTO.validate(content: req)
    let dto = try req.content.decode(PatchForumCategoryDTO.self)
    category.patch(with: dto)
    try await category.save(on: req.db)
    return try GetForumCategoryDTO(from: category, commentCounts: [:])
  }
  
  @Sendable
  func deleteByID(req: Request) async throws -> HTTPStatus {
    let id = try req.parameters.require("forumCategoryID", as: UUID.self)
    let category = try await findCategory(id: id, on: req.db)
    
    try await category.delete(on: req.db)
    return .noContent
  }
  
  private func findCategory(id: UUID, on db: any Database) async throws -> ForumCategory {
    let query = ForumCategory.query(on: db)
      .filter(\.$id == id)
      .with(\.$forumPosts) { $0.with(\.$user) }
    
    guard let category = try await query.first() else {
      throw Abort(.notFound, reason: "ForumCategory not found")
    }
    
    category.$forumPosts.value = category.$forumPosts.value?
      .filter { $0.creationDate != nil }
      .sorted { ($0.lastActivityDate ?? $0.creationDate!) > ($1.lastActivityDate ?? $1.creationDate!) }
    return category
  }
  
  private func postCounts(for categories: [ForumCategory], on db: any Database) async throws -> [UUID: Int] {
    guard !categories.isEmpty else { return [:] }
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
