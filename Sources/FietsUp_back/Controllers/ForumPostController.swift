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
      .grouped(JWTMiddleware(), RequireAdminLevelMiddleware(minimumLevel: 1))
      .groupedOpenAPI(auth: .bearer(id: "ModBearer", format: "JWT"))
    
    userProtected.post("category", ":forumCategoryID", use: self.create)
      .openAPI(
        tags: "Forum", "Posts",
        summary: "Create",
        description: "Create a forum post",
        body: .type(CreateForumPostDTO.self),
        response: .type(GetForumPostDTO.self)
      )
    
    userProtected.post(":forumPostID", "like", use: self.like)
      .openAPI(
        tags: "Forum", "Posts",
        summary: "Like a forum post, or unlike it if previously liked",
        response: .type(GetForumPostDTO.self)
      )
    
    userProtected.post(":forumPostID", "fav", use: self.fav)
      .openAPI(
        tags: "Forum", "Posts",
        summary: "Favorite a forum post, or unfavorite it if previously faved",
        response: .type(GetForumPostDTO.self)
      )
        
    userProtected.get(":forumPostID", use: self.getByID)
      .openAPI(
        tags: "Forum", "Posts",
        summary: "Get",
        description: "Find and get an existing post (and its comments) by id",
        path: .type(UUID.self),
        response: .type(GetForumPostDTO.self)
      )
    
    modProtected.patch("mod", ":forumPostID", use: self.patchByID)
      .openAPI(
        tags: "Moderation", "Forum", "Posts",
        summary: "Patch",
        description: "Find and patch an existing post by id",
        path: .type(UUID.self),
        body: .type(PatchForumPostDTO.self),
        response: .type(GetForumPostDTO.self)
      )
    
    modProtected.delete("mod", ":forumPostID", use: self.deleteByID)
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
    
    let userID = try await req.requireUser().requireID()
    let forumCategoryID = try req.parameters.require("forumCategoryID", as: UUID.self)

    guard try await ForumCategory.find(forumCategoryID, on: req.db) != nil else {
      throw Abort(.notFound, reason: "Forum category not found")
    }
    
    let post = ForumPost(from: dto, userID: userID, forumCategoryID: forumCategoryID)
    try await post.save(on: req.db)
    
    return try await GetForumPostDTO(from: post, userID: userID, on: req.db)
  }
  
  @Sendable
  func like(req: Request) async throws -> GetForumPostDTO {
    let userID = try await req.requireUser().requireID()
    let forumPostID = try req.parameters.require("forumPostID", as: UUID.self)
    
    let existingLike = try await ForumPostLike.query(on: req.db)
      .filter(\.$user.$id == userID)
      .filter(\.$forumPost.$id == forumPostID)
      .first()
    if let existingLike {
      try await existingLike.delete(on: req.db)
    } else {
      let newLike = ForumPostLike(userID: userID, forumPostID: forumPostID)
      try await newLike.save(on: req.db)
    }
    
    let forumPost = try await findForumPost(id: forumPostID, on: req.db)
    return try await GetForumPostDTO(from: forumPost, userID: userID, on: req.db)
  }
  
  @Sendable
  func fav(req: Request) async throws -> GetForumPostDTO {
    let userID = try await req.requireUser().requireID()
    let forumPostID = try req.parameters.require("forumPostID", as: UUID.self)
        
    let existingFav = try await ForumPostFav.query(on: req.db)
      .filter(\.$user.$id == userID)
      .filter(\.$forumPost.$id == forumPostID)
      .first()
    if let existingFav {
      try await existingFav.delete(on: req.db)
    } else {
      let newFav = ForumPostFav(userID: userID, forumPostID: forumPostID)
      try await newFav.save(on: req.db)
    }
    
    let forumPost = try await findForumPost(id: forumPostID, on: req.db)
    return try await GetForumPostDTO(from: forumPost, userID: userID, on: req.db)
  }
    
  @Sendable
  func getByID(req: Request) async throws -> GetForumPostDTO {
    let userID = try await req.requireUser().requireID()
    let forumPostID = try req.parameters.require("forumPostID", as: UUID.self)
    let forumPost = try await findForumPost(id: forumPostID, on: req.db)
    return try await GetForumPostDTO(from: forumPost, userID: userID, on: req.db)
  }
  
  @Sendable
  func patchByID(req: Request) async throws -> GetForumPostDTO {
    let userID = try await req.requireUser().requireID()
    let forumPostID = try req.parameters.require("forumPostID", as: UUID.self)
    let forumPost = try await findForumPost(id: forumPostID, on: req.db)

    try PatchForumPostDTO.validate(content: req)
    let dto = try req.content.decode(PatchForumPostDTO.self)
    forumPost.patch(with: dto)
    try await forumPost.save(on: req.db)
    
    return try await GetForumPostDTO(from: forumPost, userID: userID, on: req.db)
  }
  
  @Sendable
  func deleteByID(req: Request) async throws -> HTTPStatus {
    let id = try req.parameters.require("forumPostID", as: UUID.self)
    let post = try await findForumPost(id: id, on: req.db)
    
    try await post.delete(on: req.db)
    return .noContent
  }  
}
