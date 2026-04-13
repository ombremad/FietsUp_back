//
//  ForumPostController.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 26/03/2026.
//

import Vapor
import Fluent
import SQLKit

struct ForumPostController: RouteCollection {
  func boot(routes: any RoutesBuilder) throws {
    
    let request = routes.grouped("forum", "posts")
    
    let userProtected = request
      .grouped(JWTMiddleware())
      .groupedOpenAPI(auth: .bearer(id: "BearerAuth", format: "JWT"))
    
    let modProtected = request
      .grouped(RequireAdminLevelMiddleware(minimumLevel: 1))
      .groupedOpenAPI(auth: .bearer(id: "ModBearer", format: "JWT"))
    
    userProtected.post("category", ":forumCategoryID", use: self.create)
      .openAPI(
        tags: "Forum", "Posts",
        summary: "Create",
        description: "Create a forum post",
        body: .type(CreateForumPostDTO.self),
        response: .type(GetForumPostDTO.self)
      )
    
    userProtected.get("category", ":forumCategoryID", use: self.getAllInCategory)
      .openAPI(
        tags: "Forum", "Posts",
        summary: "List",
        description: "List forum posts in category",
        response: .type([GetForumPostWithCountsDTO].self)
      )
    
    userProtected.get(":forumPostID", use: self.getByID)
      .openAPI(
        tags: "Forum", "Posts",
        summary: "Get",
        description: "Find and get an existing post by id",
        path: .type(UUID.self),
        response: .type(GetForumPostDTO.self)
      )
    
    modProtected.patch(":forumPostID", use: self.patchByID)
      .openAPI(
        tags: "Moderation", "Forum", "Posts",
        summary: "Patch",
        description: "Find and patch an existing post by id",
        path: .type(UUID.self),
        body: .type(PatchForumPostDTO.self),
        response: .type(GetForumPostDTO.self)
      )
    
    modProtected.delete(":forumPostID", use: self.deleteByID)
      .openAPI(
        tags: "Moderation", "Forum", "Posts",
        summary: "Delete",
        description: "Permanently delete an existing forum post (and all its comments) by id",
        path: .type(UUID.self),
        response: .type(HTTPStatus.self)
      )
  }
  
  @Sendable
  func create(req: Request) async throws -> GetForumPostDTO {
    try CreateForumPostDTO.validate(content: req)
    let dto = try req.content.decode(CreateForumPostDTO.self)
    
    let user = try await req.requireUser()
    let userID = try user.requireID()
    let forumCategoryID = try req.parameters.require("forumCategoryID", as: UUID.self)

    guard try await ForumCategory.find(forumCategoryID, on: req.db) != nil else {
      throw Abort(.notFound, reason: "Forum category not found")
    }
    
    let post = ForumPost(from: dto, userID: userID, forumCategoryID: forumCategoryID)
    try await post.save(on: req.db)
    
    let postID = try post.requireID()
    return try GetForumPostDTO(from: try await findPost(id: postID, on: req.db))
  }
  
  @Sendable
  func getAllInCategory(req: Request) async throws -> [GetForumPostWithCountsDTO] {
    let forumCategoryID = try req.parameters.require("forumCategoryID", as: UUID.self)

    let posts = try await ForumPost.query(on: req.db)
      .filter(\.$forumCategory.$id == forumCategoryID)
      .sort(\.$lastActivityDate, .descending)
      .with(\.$user)
      .all()
    
    let countsByPostID = try await commentCounts(for: posts, on: req.db)
    
    return try posts.map { post in
      try GetForumPostWithCountsDTO(from: post, totalComments: countsByPostID[post.requireID()] ?? 0)
    }
  }
  
  @Sendable
  func getByID(req: Request) async throws -> GetForumPostDTO {
    let postID = try req.parameters.require("forumPostID", as: UUID.self)
    let post = try await findPost(id: postID, on: req.db)
    return try GetForumPostDTO(from: post)
  }
  
  @Sendable
  func patchByID(req: Request) async throws -> GetForumPostDTO {
    let postID = try req.parameters.require("forumPostID", as: UUID.self)
    let post = try await findPost(id: postID, on: req.db)
    
    try PatchForumPostDTO.validate(content: req)
    let dto = try req.content.decode(PatchForumPostDTO.self)
    post.patch(with: dto)
    try await post.save(on: req.db)
    return try GetForumPostDTO(from: post)
  }
  
  @Sendable
  func deleteByID(req: Request) async throws -> HTTPStatus {
    let id = try req.parameters.require("forumPostID", as: UUID.self)
    let post = try await findPost(id: id, on: req.db)
    
    try await post.delete(on: req.db)
    return .noContent
  }
  
  private func findPost(id: UUID, on db: any Database) async throws -> ForumPost {
    let query = ForumPost.query(on: db)
      .filter(\.$id == id)
      .with(\.$user)
      .with(\.$forumComments) { $0.with(\.$user) }
    
    guard let post = try await query.first() else {
      throw Abort(.notFound)
    }
    
    post.$forumComments.value = post.$forumComments.value?
      .filter { $0.creationDate != nil }
      .sorted { $0.creationDate! < $1.creationDate! }
    
    return post
  }
  
  private func commentCounts(for posts: [ForumPost], on db: any Database) async throws -> [UUID: Int] {
    guard let sql = db as? any SQLDatabase else { throw Abort(.internalServerError) }
    
    let idList = try posts
      .map { "UNHEX('\(try $0.requireID().hexString)')" }
      .joined(separator: ", ")
    
    let rows = try await sql.raw("""
        SELECT HEX(id_forum_post) as id_forum_post, COUNT(*) as total_comments
        FROM \(unsafeRaw: ForumComment.schema)
        WHERE id_forum_post IN (\(unsafeRaw: idList))
        GROUP BY id_forum_post
        """).all()
    
    return try Dictionary(uniqueKeysWithValues: rows.map {
      let hex = try $0.decode(column: "id_forum_post", as: String.self)
      guard let uuid = UUID(hex: hex) else { throw Abort(.internalServerError) }
      return (uuid, try $0.decode(column: "total_comments", as: Int.self))
    })
  }
}
