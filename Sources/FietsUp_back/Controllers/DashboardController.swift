//
//  DashboardController.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 17/04/2026.
//

import Vapor
import Fluent

struct DashboardController: RouteCollection {
  func boot(routes: any RoutesBuilder) throws {
    
    let request = routes.grouped("dashboard")
    
    let userProtected = request
      .grouped(JWTMiddleware())
      .groupedOpenAPI(auth: .bearer(id: "BearerAuth", format: "JWT"))
    
    userProtected.get("favorites", use: self.get)
      .openAPI(
        tags: "Dashboard",
        summary: "Get",
        description: "Get favorites",
        response: .type(GetAllFavoritesDTO.self)
      )
  }
  
  @Sendable
  func get(req: Request) async throws -> GetAllFavoritesDTO {
    let user = try req.requireUser()
    
    async let forumPostFavs = try await user.$forumPostFavs.query(on: req.db)
      .with(\.$user)
      .sort(\.$creationDate, .descending)
      .all()
    
    async let forumCommentFavs = try await user.$forumCommentFavs.query(on: req.db)
      .with(\.$user)
      .sort(\.$creationDate, .descending)
      .all()
    
    async let dangerPostFavs = try await user.$dangerPostFavs.query(on: req.db)
      .with(\.$user)
      .with(\.$dangerCategory)
      .sort(\.$creationDate, .descending)
      .all()
    
    async let dangerCommentFavs = try await user.$dangerCommentFavs.query(on: req.db)
      .with(\.$user)
      .sort(\.$creationDate, .descending)
      .all()
    
    return try await GetAllFavoritesDTO(
      forumPosts: forumPostFavs,
      forumComments: forumCommentFavs,
      dangerPosts: dangerPostFavs,
      dangerComments: dangerCommentFavs,
    )
  }
}
