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
    // TODO: refactoring needed for pagination
    async let forumPostReports = try await ForumPostReport.query(on: req.db)
      .filter(\.$processDate == nil)
      .sort(\.$creationDate, .ascending)
      .with(\.$forumPost, { $0.with(\.$user) })
      .with(\.$user)
      .with(\.$moderationCategory)
      .all()
    async let forumCommentReports = try await ForumCommentReport.query(on: req.db)
      .filter(\.$processDate == nil)
      .sort(\.$creationDate, .ascending)
      .with(\.$forumComment, { $0.with(\.$user) })
      .with(\.$user)
      .with(\.$moderationCategory)
      .all()
   async let dangerPostReports = try await DangerPostReport.query(on: req.db)
      .filter(\.$processDate == nil)
      .sort(\.$creationDate, .ascending)
      .with(\.$dangerPost, { $0.with(\.$user).with(\.$dangerCategory) })
      .with(\.$user)
      .with(\.$moderationCategory)
      .all()
    async let dangerCommentReports = try await DangerCommentReport.query(on: req.db)
      .filter(\.$processDate == nil)
      .sort(\.$creationDate, .ascending)
      .with(\.$dangerComment, { $0.with(\.$user) })
      .with(\.$user)
      .with(\.$moderationCategory)
      .all()

    return try await GetAllReportsDTO(forumPosts: forumPostReports, forumComments: forumCommentReports, dangerPosts: dangerPostReports, dangerComments: dangerCommentReports)
  }
}
