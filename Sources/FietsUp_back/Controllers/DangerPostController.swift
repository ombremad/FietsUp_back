//
//  DangerPostController.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 26/03/2026.
//

import Vapor
import Fluent
import SQLKit

struct DangerPostController: RouteCollection {
  func boot(routes: any RoutesBuilder) throws {
    
    let request = routes.grouped("dangers", "posts")
    
    let userProtected = request
      .grouped(JWTMiddleware())
      .groupedOpenAPI(auth: .bearer(id: "BearerAuth", format: "JWT"))
    
    let modProtected = request
      .grouped(JWTMiddleware(), RequireAdminLevelMiddleware(minimumLevel: 1))
      .groupedOpenAPI(auth: .bearer(id: "ModBearer", format: "JWT"))
    
    userProtected.post("category", ":dangerCategoryID", use: self.create)
      .openAPI(
        tags: "Dangers", "Posts",
        summary: "Create",
        description: "Create a danger post",
        body: .type(CreateDangerPostDTO.self),
        response: .type(GetDangerPostDTO.self)
      )
    
    userProtected.post(":dangerPostID", "like", use: self.like)
      .openAPI(
        tags: "Dangers", "Posts",
        summary: "Like a danger post, or unlike it if previously liked",
        response: .type(GetDangerPostDTO.self)
      )
    
    userProtected.post(":dangerPostID", "fav", use: self.fav)
      .openAPI(
        tags: "Dangers", "Posts",
        summary: "Favorite a danger post, or unfavorite it if previously faved",
        response: .type(GetDangerPostDTO.self)
      )
    
    userProtected.get(use: self.getAll)
      .openAPI(
        tags: "Dangers", "Posts",
        summary: "List",
        description: "List danger posts",
        response: .type([GetDangerPostWithCountsDTO].self)
      )
    
    userProtected.get(":dangerPostID", use: self.getByID)
      .openAPI(
        tags: "Dangers", "Posts",
        summary: "Get",
        description: "Find and get an existing danger post by id",
        path: .type(UUID.self),
        response: .type(GetDangerPostDTO.self)
      )
    
    modProtected.patch(":dangerPostID", use: self.patchByID)
      .openAPI(
        tags: "Dangers", "Posts",
        summary: "Patch",
        description: "Find and patch an existing danger post by id",
        path: .type(UUID.self),
        body: .type(PatchDangerPostDTO.self),
        response: .type(GetDangerPostDTO.self)
      )
    
    modProtected.delete(":dangerPostID", use: self.deleteByID)
      .openAPI(
        tags: "Dangers", "Posts",
        summary: "Delete",
        description: "Permanently delete an existing danger post (and all its comments) by id",
        path: .type(UUID.self),
        response: .type(HTTPStatus.self)
      )
  }
  
  @Sendable
  func create(req: Request) async throws -> GetDangerPostDTO {
    try CreateDangerPostDTO.validate(content: req)
    let dto = try req.content.decode(CreateDangerPostDTO.self)
    
    let userID = try await req.requireUser().requireID()
    let dangerCategoryID = try req.parameters.require("dangerCategoryID", as: UUID.self)
    
    guard try await DangerCategory.find(dangerCategoryID, on: req.db) != nil else {
      throw Abort(.notFound, reason: "DangerCategory not found")
    }
    
    let post = DangerPost(from: dto, userID: userID, dangerCategoryID: dangerCategoryID)
    try await post.save(on: req.db)
    
    return try await populateDangerPostDTO(from: post, userID: userID, on: req.db)
  }
  
  @Sendable
  func like(req: Request) async throws -> GetDangerPostDTO {
    let userID = try await req.requireUser().requireID()
    let dangerPostID = try req.parameters.require("dangerPostID", as: UUID.self)
    
    let existingLike = try await DangerPostLike.query(on: req.db)
      .filter(\.$user.$id == userID)
      .filter(\.$dangerPost.$id == dangerPostID)
      .first()
    if let existingLike {
      try await existingLike.delete(on: req.db)
    } else {
      let newLike = DangerPostLike(userID: userID, dangerPostID: dangerPostID)
      try await newLike.save(on: req.db)
    }
    
    let dangerPost = try await findDangerPost(id: dangerPostID, on: req.db)
    return try await populateDangerPostDTO(from: dangerPost, userID: userID, on: req.db)
  }
  
  @Sendable
  func fav(req: Request) async throws -> GetDangerPostDTO {
    let userID = try await req.requireUser().requireID()
    let dangerPostID = try req.parameters.require("dangerPostID", as: UUID.self)
    
    let existingFav = try await DangerPostFav.query(on: req.db)
      .filter(\.$user.$id == userID)
      .filter(\.$dangerPost.$id == dangerPostID)
      .first()
    if let existingFav {
      try await existingFav.delete(on: req.db)
    } else {
      let newFav = DangerPostFav(userID: userID, dangerPostID: dangerPostID)
      try await newFav.save(on: req.db)
    }
    
    let dangerPost = try await findDangerPost(id: dangerPostID, on: req.db)
    return try await populateDangerPostDTO(from: dangerPost, userID: userID, on: req.db)
  }
  
  @Sendable
  func getAll(req: Request) async throws -> [GetDangerPostWithCountsDTO] {
    let posts = try await DangerPost.query(on: req.db)
      .sort(\.$creationDate, .descending)
      .with(\.$user)
      .with(\.$dangerCategory)
      .all()
    
    let countsByPostID = try await commentCounts(for: posts, on: req.db)
    
    return try posts.map { post in
      try GetDangerPostWithCountsDTO(from: post, totalComments: countsByPostID[post.requireID()] ?? 0)
    }
  }
  
  @Sendable
  func getByID(req: Request) async throws -> GetDangerPostDTO {
    let userID = try await req.requireUser().requireID()
    let dangerPostID = try req.parameters.require("dangerPostID", as: UUID.self)
    let dangerPost = try await findDangerPost(id: dangerPostID, on: req.db)
    return try await populateDangerPostDTO(from: dangerPost, userID: userID, on: req.db)
  }
  
  @Sendable
  func patchByID(req: Request) async throws -> GetDangerPostDTO {
    let userID = try await req.requireUser().requireID()
    let dangerPostID = try req.parameters.require("dangerPostID", as: UUID.self)
    let dangerPost = try await findDangerPost(id: dangerPostID, on: req.db)
    
    try PatchDangerPostDTO.validate(content: req)
    let dto = try req.content.decode(PatchDangerPostDTO.self)
    dangerPost.patch(with: dto)
    try await dangerPost.save(on: req.db)
    
    return try await populateDangerPostDTO(from: dangerPost, userID: userID, on: req.db)
  }
  
  @Sendable
  func deleteByID(req: Request) async throws -> HTTPStatus {
    let id = try req.parameters.require("dangerPostID", as: UUID.self)
    let post = try await findDangerPost(id: id, on: req.db)
    
    try await post.delete(on: req.db)
    return .noContent
  }
    
  private func commentCounts(for posts: [DangerPost], on db: any Database) async throws -> [UUID: Int] {
    guard !posts.isEmpty else { return [:] }
    guard let sql = db as? any SQLDatabase else { throw Abort(.internalServerError) }
    
    let idList = try posts
      .map { "UNHEX('\(try $0.requireID().hexString)')" }
      .joined(separator: ", ")
    
    let rows = try await sql.raw("""
        SELECT HEX(id_danger_post) as id_danger_post, COUNT(*) as total_comments
        FROM \(unsafeRaw: DangerComment.schema)
        WHERE id_danger_post IN (\(unsafeRaw: idList))
        GROUP BY id_danger_post
        """).all()
    
    return try Dictionary(uniqueKeysWithValues: rows.map {
      let hex = try $0.decode(column: "id_danger_post", as: String.self)
      guard let uuid = UUID(hex: hex) else { throw Abort(.internalServerError) }
      return (uuid, try $0.decode(column: "total_comments", as: Int.self))
    })
  }
}
