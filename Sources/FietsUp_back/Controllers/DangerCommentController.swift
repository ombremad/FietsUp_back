//
//  DangerCommentController.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 13/04/2026.
//

import Vapor
import Fluent

struct DangerCommentController: RouteCollection {
  func boot(routes: any RoutesBuilder) throws {
    
    let request = routes.grouped("dangers", "comments")
    
    let userProtected = request
      .grouped(JWTMiddleware())
      .groupedOpenAPI(auth: .bearer(id: "BearerAuth", format: "JWT"))
    
    let modProtected = request
      .grouped(JWTMiddleware(), RequireAdminLevelMiddleware(minimumLevel: 1))
      .groupedOpenAPI(auth: .bearer(id: "ModBearer", format: "JWT"))
    
    userProtected.post("post", ":dangerPostID", use: self.create)
      .openAPI(
        tags: "Dangers", "Comments",
        summary: "Create",
        description: "Create a danger comment",
        body: .type(CreateDangerCommentDTO.self),
        response: .type(GetDangerPostDTO.self)
      )
    
    userProtected.post(":dangerCommentID", "like", use: self.like)
      .openAPI(
        tags: "Dangers", "Comments",
        summary: "Like a danger comment, or unlike it if previously liked",
        response: .type(GetDangerPostDTO.self)
      )
    
    userProtected.post(":dangerCommentID", "fav", use: self.fav)
      .openAPI(
        tags: "Dangers", "Comments",
        summary: "Favorite a danger comment, or unfavorite it if previously faved",
        response: .type(GetDangerPostDTO.self)
      )
    
    modProtected.patch(":dangerCommentID", use: self.patchByID)
      .openAPI(
        tags: "Dangers", "Comments",
        summary: "Patch",
        description: "Find and patch an existing danger comment by id",
        path: .type(UUID.self),
        body: .type(PatchDangerCommentDTO.self),
        response: .type(GetDangerCommentDTO.self)
      )
    
    modProtected.delete(":dangerCommentID", use: self.deleteByID)
      .openAPI(
        tags: "Dangers", "Comments",
        summary: "Delete",
        description: "Permanently delete an existing danger comment by id",
        path: .type(UUID.self),
        response: .type(HTTPStatus.self)
      )
  }
  
  @Sendable
  func create(req: Request) async throws -> GetDangerPostDTO {
    try CreateDangerCommentDTO.validate(content: req)
    let dto = try req.content.decode(CreateDangerCommentDTO.self)
    
    let userID = try await req.requireUser().requireID()
    let dangerPostID = try req.parameters.require("dangerPostID", as: UUID.self)
    let dangerPost = try await findDangerPost(id: dangerPostID, on: req.db)
    
    let comment = DangerComment(from: dto, userID: userID, dangerPostID: dangerPostID)
    try await comment.save(on: req.db)
    
    return try await populateDangerPostDTO(from: dangerPost, userID: userID, on: req.db)
  }
  
  @Sendable
  func like(req: Request) async throws -> GetDangerPostDTO {
    let userID = try await req.requireUser().requireID()
    let dangerCommentID = try req.parameters.require("dangerCommentID", as: UUID.self)
    guard let dangerComment = try await DangerComment.find(dangerCommentID, on: req.db) else {
      throw Abort(.notFound, reason: "DangerComment not found")
    }
    
    let dangerPostID = dangerComment.$dangerPost.id
    let dangerPost = try await findDangerPost(id: dangerPostID, on: req.db)
    
    let existingLike = try await DangerCommentLike.query(on: req.db)
      .filter(\.$user.$id == userID)
      .filter(\.$dangerComment.$id == dangerCommentID)
      .first()
    if let existingLike {
      try await existingLike.delete(on: req.db)
    } else {
      let newLike = DangerCommentLike(userID: userID, dangerCommentID: dangerCommentID)
      try await newLike.save(on: req.db)
    }
    
    return try await populateDangerPostDTO(from: dangerPost, userID: userID, on: req.db)
  }
  
  @Sendable
  func fav(req: Request) async throws -> GetDangerPostDTO {
    let userID = try await req.requireUser().requireID()
    let dangerCommentID = try req.parameters.require("dangerCommentID", as: UUID.self)
    guard let dangerComment = try await DangerComment.find(dangerCommentID, on: req.db) else {
      throw Abort(.notFound, reason: "DangerComment not found")
    }
    
    let dangerPostID = dangerComment.$dangerPost.id
    let dangerPost = try await findDangerPost(id: dangerPostID, on: req.db)
    
    let existingFav = try await DangerCommentFav.query(on: req.db)
      .filter(\.$user.$id == userID)
      .filter(\.$dangerComment.$id == dangerCommentID)
      .first()
    if let existingFav {
      try await existingFav.delete(on: req.db)
    } else {
      let newFav = DangerCommentFav(userID: userID, dangerCommentID: dangerCommentID)
      try await newFav.save(on: req.db)
    }
    
    return try await populateDangerPostDTO(from: dangerPost, userID: userID, on: req.db)
  }
  
  @Sendable
  func patchByID(req: Request) async throws -> GetDangerCommentDTO {
    let userID = try await req.requireUser().requireID()
    let commentID = try req.parameters.require("dangerCommentID", as: UUID.self)
    let comment = try await findDangerComment(id: commentID, on: req.db)
    
    try PatchDangerPostDTO.validate(content: req)
    let dto = try req.content.decode(PatchDangerCommentDTO.self)
    comment.patch(with: dto)
    try await comment.save(on: req.db)
    
    return try await populateDangerCommentDTO(from: comment, userID: userID, on: req.db)
  }
  
  @Sendable
  func deleteByID(req: Request) async throws -> HTTPStatus {
    let id = try req.parameters.require("dangerCommentID", as: UUID.self)
    let comment = try await findDangerComment(id: id, on: req.db)
    
    try await comment.delete(on: req.db)
    return .noContent
  }
  
  private func findDangerComment(id: UUID, on db: any Database) async throws -> DangerComment {
    let comment = try await DangerComment.query(on: db)
      .filter(\.$id == id)
      .with(\.$user)
      .first()
    return try returnOrFail(comment)
  }
}
