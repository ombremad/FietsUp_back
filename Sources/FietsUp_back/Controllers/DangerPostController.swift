//
//  DangerPostController.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 26/03/2026.
//

import Vapor
import Fluent

struct DangerPostController: RouteCollection {
  func boot(routes: any RoutesBuilder) throws {
    
    let request = routes.grouped("dangers", "posts")
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
        tags: "Dangers", "Posts",
        summary: "Create",
        description: "Create a danger post",
        body: .type(CreateDangerPostDTO.self),
        response: .type(GetDangerPostDTO.self)
      )
    
    userProtected.get(":id", use: self.getById)
      .openAPI(
        tags: "Dangers", "Posts",
        summary: "Get",
        description: "Find and get an existing danger post by id",
        path: .type(UUID.self),
        response: .type(GetDangerPostDTO.self)
      )
    
    modProtected.patch(":id", use: self.patchById)
      .openAPI(
        tags: "Dangers", "Posts",
        summary: "Patch",
        description: "Find and patch an existing danger post by id",
        path: .type(UUID.self),
        body: .type(PatchDangerPostDTO.self),
        response: .type(GetDangerPostDTO.self)
      )
    
    modProtected.delete(":id", use: self.deleteById)
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
    
    let user = try await req.requireUser()
    let userID = try user.requireID()
    let dangerCategoryID = try req.parameters.require("categoryID", as: UUID.self)
    
    let post = DangerPost(from: dto, userID: userID, dangerCategoryID: dangerCategoryID)
    try await post.save(on: req.db)
    
    let postID = try post.requireID()
    return try GetDangerPostDTO(from: try await findPost(id: postID, on: req.db))
  }
  
  @Sendable
  func getById(req: Request) async throws -> GetDangerPostDTO {
    let postID = try req.parameters.require("id", as: UUID.self)
    let post = try await findPost(id: postID, on: req.db)
    return try GetDangerPostDTO(from: post)
  }
  
  @Sendable
  func patchById(req: Request) async throws -> GetDangerPostDTO {
    let postID = try req.parameters.require("id", as: UUID.self)
    let post = try await findPost(id: postID, on: req.db)
    
    try PatchDangerPostDTO.validate(content: req)
    let dto = try req.content.decode(PatchDangerPostDTO.self)
    post.patch(with: dto)
    try await post.save(on: req.db)
    return try GetDangerPostDTO(from: post)
  }
  
  @Sendable
  func deleteById(req: Request) async throws -> HTTPStatus {
    let id = try req.parameters.require("id", as: UUID.self)
    let post = try await findPost(id: id, on: req.db)
    
    try await post.delete(on: req.db)
    return .noContent
  }
  
  private func findPost(id: UUID, on db: any Database) async throws -> DangerPost {
    let query = DangerPost.query(on: db)
      .filter(\.$id == id)
      .with(\.$user)
      .with(\.$dangerComments) { comment in
        comment.with(\.$user)
      }
    
    guard let post = try await query.first() else {
      throw Abort(.notFound)
    }
    return post
  }

}
