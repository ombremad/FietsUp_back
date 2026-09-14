//
//  ReportController.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 08/07/2026.
//

import Vapor
import Fluent

struct ReportController: RouteCollection {
  func boot(routes: any RoutesBuilder) throws {
    let request = routes.grouped("reports")
    
    let modProtected = request
      .grouped(JWTMiddleware(), RequireAdminLevelMiddleware(minimumLevel: 1))
      .groupedOpenAPI(auth: .bearer(id: "ModBearer", format: "JWT"))
    
    modProtected.get("pending", use: self.pending)
      .openAPI(
        tags: "Reports",
        summary: "Index",
        description: "See all kinds of pending reports",
        response: .type(GetAllReportsDTO.self)
      )
  }
  
  @Sendable
  func pending(req: Request) async throws -> GetAllReportsDTO {
    async let forumPostReports = try await ForumPostReport.query(on: req.db)
      .filter(\.$processDate == nil)
      .with(\.$forumPost, { $0.with(\.$user) })
      .with(\.$user)
      .with(\.$moderationCategory)
      .sort(\.$creationDate, .ascending)
      .all()
    
    async let forumCommentReports = try await ForumCommentReport.query(on: req.db)
      .filter(\.$processDate == nil)
      .with(\.$forumComment, { $0.with(\.$user) })
      .with(\.$user)
      .with(\.$moderationCategory)
      .sort(\.$creationDate, .ascending)
      .all()
    
   async let dangerPostReports = try await DangerPostReport.query(on: req.db)
      .filter(\.$processDate == nil)
      .with(\.$dangerPost, { $0.with(\.$user).with(\.$dangerCategory) })
      .with(\.$user)
      .with(\.$moderationCategory)
      .sort(\.$creationDate, .ascending)
      .all()
    
    async let dangerCommentReports = try await DangerCommentReport.query(on: req.db)
      .filter(\.$processDate == nil)
      .with(\.$dangerComment, { $0.with(\.$user) })
      .with(\.$user)
      .with(\.$moderationCategory)
      .sort(\.$creationDate, .ascending)
      .all()

    return try await GetAllReportsDTO(
      forumPosts: forumPostReports,
      forumComments: forumCommentReports,
      dangerPosts: dangerPostReports,
      dangerComments: dangerCommentReports,
    )
  }
}
