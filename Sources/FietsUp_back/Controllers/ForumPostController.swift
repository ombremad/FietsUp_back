//
//  ForumPostController.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 26/03/2026.
//

import Vapor
import Fluent

struct ForumPostController: RouteCollection {
  func boot(routes: any RoutesBuilder) throws {
    
    let request = routes.grouped("forum", "posts")
    let userProtected =
    request
      .grouped(JWTMiddleware())
      .groupedOpenAPI(auth: .bearer(id: "BearerAuth", format: "JWT"))
    let modProtected =
    request
      .grouped(JWTMiddleware(), RequireAdminLevelMiddleware(minimumLevel: 1))
      .groupedOpenAPI(auth: .bearer(id: "ModBearer", format: "JWT"))
    
    userProtected.post(":categoryID", use: self.create)
      .openAPI(
        tags: "Forum", "Posts",
        summary: "Create",
        description: "Create a forum post",
        body: .type(CreateForumPostDTO.self),
        response: .type(GetForumPostDTO.self)
      )
        
    userProtected.get(":id", use: self.getById)
      .openAPI(
        tags: "Forum", "Posts",
        summary: "Get",
        description: "Find and get an existing post by id",
        path: .type(UUID.self),
        response: .type(GetForumPostDTO.self)
      )
    
    modProtected.patch(":id", use: self.patchById)
      .openAPI(
        tags: "Forum", "Posts",
        summary: "Patch",
        description: "Find and patch an existing post by id",
        path: .type(UUID.self),
        body: .type(PatchForumPostDTO.self),
        response: .type(GetForumPostDTO.self)
      )
    
    modProtected.delete(":id", use: self.deleteById)
      .openAPI(
        tags: "Forum", "Posts",
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
    let forumCategoryID = try req.parameters.require("categoryID", as: UUID.self)
    
    let post = ForumPost(from: dto, userID: userID, forumCategoryID: forumCategoryID)
    try await post.save(on: req.db)
    
    let postID = try post.requireID()
    return try GetForumPostDTO(from: try await findPost(id: postID, on: req.db))
  }
  
  @Sendable
  func getById(req: Request) async throws -> GetForumPostDTO {
    let postID = try req.parameters.require("id", as: UUID.self)
    let post = try await findPost(id: postID, on: req.db)
    return try GetForumPostDTO(from: post)
  }
  
  @Sendable
  func patchById(req: Request) async throws -> GetForumPostDTO {
    let postID = try req.parameters.require("id", as: UUID.self)
    let post = try await findPost(id: postID, on: req.db)
    
    try PatchForumPostDTO.validate(content: req)
    let dto = try req.content.decode(PatchForumPostDTO.self)
    post.patch(with: dto)
    try await post.save(on: req.db)
    return try GetForumPostDTO(from: post)
  }
  
  @Sendable
  func deleteById(req: Request) async throws -> HTTPStatus {
    let id = try req.parameters.require("id", as: UUID.self)
    let post = try await findPost(id: id, on: req.db)
    
    try await post.delete(on: req.db)
    return .noContent
  }
  
  private func findPost(id: UUID, on db: any Database) async throws -> ForumPost {
    let query = ForumPost.query(on: db)
      .filter(\.$id == id)
      .with(\.$user)
      .with(\.$forumComments) { comment in
        comment.with(\.$user)
      }
    
    guard let post = try await query.first() else {
      throw Abort(.notFound)
    }
    
    post.$forumComments.value = post.$forumComments.value?
      .filter { $0.creationDate != nil }
      .sorted { $0.creationDate! < $1.creationDate! }
    
    return post
  }
}
