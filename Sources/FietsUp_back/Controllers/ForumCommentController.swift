//
//  ForumCommentController.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 13/04/2026.
//

import Vapor
import Fluent

struct ForumCommentController: RouteCollection {
  func boot(routes: any RoutesBuilder) throws {
    
    let request = routes.grouped("forum", "comments")
    
    let userProtected = request
      .grouped(JWTMiddleware())
      .groupedOpenAPI(auth: .bearer(id: "BearerAuth", format: "JWT"))

    let modProtected = request
        .grouped(JWTMiddleware(), RequireAdminLevelMiddleware(minimumLevel: 1))
        .groupedOpenAPI(auth: .bearer(id: "ModBearer", format: "JWT"))
    
    userProtected.post("post", ":forumPostID", use: self.create)
      .openAPI(
        tags: "Forum", "Comments",
        summary: "Create a forum comment",
        body: .type(CreateForumCommentDTO.self),
        response: .type(GetForumPostDTO.self)
      )
    
    userProtected.post(":forumCommentID", "like", use: self.like)
      .openAPI(
        tags: "Forum", "Comments",
        summary: "Like a forum comment, or unlike it if previously liked",
        response: .type(GetForumPostDTO.self)
      )
    
    userProtected.post(":forumCommentID", "fav", use: self.fav)
      .openAPI(
        tags: "Forum", "Comments",
        summary: "Favorite a forum comment, or unfavorite it if previously faved",
        response: .type(GetForumPostDTO.self)
      )
    
    modProtected.patch("mod", ":forumCommentID", use: self.patchByID)
      .openAPI(
        tags: "Moderation", "Forum", "Comments",
        summary: "Find and patch an existing comment by id",
        path: .type(UUID.self),
        body: .type(PatchForumCommentDTO.self),
        response: .type(GetForumCommentDTO.self)
      )
    
    modProtected.delete("mod", ":forumCommentID", use: self.deleteByID)
      .openAPI(
        tags: "Moderation", "Forum", "Comments",
        summary: "Delete",
        description: "Permanently delete an existing forum comment by id",
        path: .type(UUID.self),
        response: .type(HTTPStatus.self)
      )
  }
  
  @Sendable
  func create(req: Request) async throws -> GetForumPostDTO {
    try CreateForumCommentDTO.validate(content: req)
    let dto = try req.content.decode(CreateForumCommentDTO.self)
    
    let userID = try await req.requireUser().requireID()
    let forumPostID = try req.parameters.require("forumPostID", as: UUID.self)
    let forumPost = try await findForumPost(id: forumPostID, on: req.db)

    let comment = ForumComment(from: dto, userID: userID, forumPostID: forumPostID)
    try await comment.save(on: req.db)
    
    return try await GetForumPostDTO(from: forumPost, userID: userID, on: req.db)
  }
  
  @Sendable
  func like(req: Request) async throws -> GetForumPostDTO {
    let userID = try await req.requireUser().requireID()
    let forumCommentID = try req.parameters.require("forumCommentID", as: UUID.self)
    guard let forumComment = try await ForumComment.find(forumCommentID, on: req.db) else { throw Abort(.notFound, reason: "Forum comment not found") }
    
    let forumPostID = forumComment.$forumPost.id
    let forumPost = try await findForumPost(id: forumPostID, on: req.db)

    let existingLike = try await ForumCommentLike.query(on: req.db)
      .filter(\.$user.$id == userID)
      .filter(\.$forumComment.$id == forumCommentID)
      .first()
    if let existingLike {
      try await existingLike.delete(on: req.db)
    } else {
      let newLike = ForumCommentLike(userID: userID, forumCommentID: forumCommentID)
      try await newLike.save(on: req.db)
    }

    return try await GetForumPostDTO(from: forumPost, userID: userID, on: req.db)
  }
  
  @Sendable
  func fav(req: Request) async throws -> GetForumPostDTO {
    let userID = try await req.requireUser().requireID()
    let forumCommentID = try req.parameters.require("forumCommentID", as: UUID.self)
    guard let forumComment = try await ForumComment.find(forumCommentID, on: req.db) else { throw Abort(.notFound, reason: "Forum comment not found") }
    
    let forumPostID = forumComment.$forumPost.id
    let forumPost = try await findForumPost(id: forumPostID, on: req.db)

    let existingFav = try await ForumCommentFav.query(on: req.db)
      .filter(\.$user.$id == userID)
      .filter(\.$forumComment.$id == forumCommentID)
      .first()
    if let existingFav {
      try await existingFav.delete(on: req.db)
    } else {
      let newFav = ForumCommentFav(userID: userID, forumCommentID: forumCommentID)
      try await newFav.save(on: req.db)
    }
    
    return try await GetForumPostDTO(from: forumPost, userID: userID, on: req.db)
  }
  
  @Sendable
  func patchByID(req: Request) async throws -> GetForumCommentDTO {
    let userID = try await req.requireUser().requireID()
    let commentID = try req.parameters.require("forumCommentID", as: UUID.self)
    let comment = try await findForumComment(id: commentID, on: req.db)
    
    try PatchForumCommentDTO.validate(content: req)
    let dto = try req.content.decode(PatchForumCommentDTO.self)
    comment.patch(with: dto)
    try await comment.save(on: req.db)
    
    return try await buildForumCommentDTO(forumCommentID: commentID, userID: userID, on: req.db)
  }
  
  @Sendable
  func deleteByID(req: Request) async throws -> HTTPStatus {
    let id = try req.parameters.require("forumCommentID", as: UUID.self)
    let comment = try await findForumComment(id: id, on: req.db)
    
    try await comment.delete(on: req.db)
    return .noContent
  }
  
  private func findForumComment(id: UUID, on db: any Database) async throws -> ForumComment {
    let comment = try await ForumComment.query(on: db)
      .filter(\.$id == id)
      .with(\.$user)
      .first()
    
    return try returnOrFail(comment)
  }
  
  private func buildForumCommentDTO(forumCommentID: UUID, userID: UUID, on db: any Database) async throws -> GetForumCommentDTO {
    async let comment = try await findForumComment(id: forumCommentID, on: db)
    async let likeCount = try await getLikeCount(forumCommentID: forumCommentID, on: db)
    async let likedByUser = try await getLikedByUser(forumCommentID: forumCommentID, userID: userID, on: db)
    async let favedByUser = try await getFavedByUser(forumCommentID: forumCommentID, userID: userID, on: db)
    return try await GetForumCommentDTO(from: comment, likeCount: likeCount, likedByUser: likedByUser, favedByUser: favedByUser)
  }
  
  private func getLikeCount(forumCommentID: UUID, on db: any Database) async throws -> Int {
    return try await ForumCommentLike.query(on: db)
      .filter(\.$forumComment.$id == forumCommentID)
      .count()
  }
  
  private func getLikedByUser(forumCommentID: UUID, userID: UUID, on db: any Database) async throws -> Bool {
    let likedByUser = try await ForumCommentLike.query(on: db)
      .filter(\.$forumComment.$id == forumCommentID)
      .filter(\.$user.$id == userID)
      .count()
    return likedByUser > 0
  }
  
  private func getFavedByUser(forumCommentID: UUID, userID: UUID, on db: any Database) async throws -> Bool {
    let favedByUser = try await ForumCommentFav.query(on: db)
      .filter(\.$forumComment.$id == forumCommentID)
      .filter(\.$user.$id == userID)
      .count()
    return favedByUser > 0
  }

}
