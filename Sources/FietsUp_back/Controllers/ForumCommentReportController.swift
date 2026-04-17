//
//  ForumCommentReportController.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 17/04/2026.
//

import Vapor
import Fluent

struct ForumCommentReportController: RouteCollection {
  func boot(routes: any RoutesBuilder) throws {
    
    let request = routes.grouped("reports", "forum", "comments")
    
    let userProtected = request
      .grouped(JWTMiddleware())
      .groupedOpenAPI(auth: .bearer(id: "BearerAuth", format: "JWT"))
    
    let modProtected = request
      .grouped(JWTMiddleware(), RequireAdminLevelMiddleware(minimumLevel: 1))
      .groupedOpenAPI(auth: .bearer(id: "ModBearer", format: "JWT"))
    
    userProtected.post(":forumCommentID", use: self.create)
      .openAPI(
        tags: "Reports", "Forum", "Comments",
        summary: "Create",
        description: "Create a forum comment report",
        body: .type(CreateForumCommentReportDTO.self),
        response: .type(GetForumCommentReportDTO.self)
      )
    
    modProtected.get("pending", use: self.pending)
      .openAPI(
        tags: "Reports", "Forum", "Comments",
        summary: "Index",
        description: "See pending forum comment reports",
        response: .type([GetForumCommentReportDTO].self)
      )
    
    modProtected.patch("process", ":reportID", use: self.process)
      .openAPI(
        tags: "Reports", "Forum", "Comments",
        summary: "Process",
        description: "Mark a forum comment report as processed by a moderator",
        body: .type(ProcessForumCommentReportDTO.self),
        response: .type(GetForumCommentReportDTO.self)
      )
  }
  
  @Sendable
  func create(req: Request) async throws -> GetForumCommentReportDTO {
    let dto = try req.content.decode(CreateForumCommentReportDTO.self)
    let userID = try await req.requireUser().requireID()
    let forumCommentID = try req.parameters.require("forumCommentID", as: UUID.self)
    
    guard try await ForumComment.find(forumCommentID, on: req.db) != nil else {
      throw Abort(.notFound, reason: "ForumComment not found")
    }
    
    let report = ForumCommentReport(from: dto, userID: userID, forumCommentID: forumCommentID)
    try await report.save(on: req.db)
    
    return try GetForumCommentReportDTO(from: await findReport(id: report.requireID(), on: req.db))
  }
  
  @Sendable
  func pending(req: Request) async throws -> [GetForumCommentReportDTO] {
    let pendingReports = try await ForumCommentReport.query(on: req.db)
      .filter(\.$processDate == nil)
      .sort(\.$creationDate, .ascending)
      .with(\.$forumComment, { $0.with(\.$user) })
      .with(\.$user)
      .with(\.$moderationCategory)
      .all()
    
    return try pendingReports.map { try GetForumCommentReportDTO(from: $0) }
  }
  
  @Sendable
  func process(req: Request) async throws -> GetForumCommentReportDTO {
    try ProcessForumCommentReportDTO.validate(content: req)
    let dto = try req.content.decode(ProcessForumCommentReportDTO.self)
    let reportID = try req.parameters.require("reportID", as: UUID.self)
    
    guard let report = try await ForumCommentReport.find(reportID, on: req.db) else {
      throw Abort(.notFound, reason: "ForumCommentReport not found")
    }
    
    guard report.processDate == nil else {
      throw Abort(.badRequest, reason: "Report already processed")
    }
    
    report.process(with: dto)
    try await report.save(on: req.db)
    
    return try GetForumCommentReportDTO(from: await findReport(id: report.requireID(), on: req.db))
  }
  
  private func findReport(id: UUID, on db: any Database) async throws -> ForumCommentReport {
    let report = try await ForumCommentReport.query(on: db)
      .filter(\.$id == id)
      .with(\.$forumComment, { $0.with(\.$user) })
      .with(\.$user)
      .with(\.$moderationCategory)
      .first()
    return try returnOrFail(report)
  }
}
