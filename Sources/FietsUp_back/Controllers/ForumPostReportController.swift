//
//  ForumPostReportController.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 16/04/2026.
//

import Vapor
import Fluent

struct ForumPostReportController: RouteCollection {
  func boot(routes: any RoutesBuilder) throws {
    
    let request = routes.grouped("reports", "forum", "posts")
    
    let userProtected = request
      .grouped(JWTMiddleware())
      .groupedOpenAPI(auth: .bearer(id: "BearerAuth", format: "JWT"))
    
    let modProtected = request
      .grouped(JWTMiddleware(), RequireAdminLevelMiddleware(minimumLevel: 1))
      .groupedOpenAPI(auth: .bearer(id: "ModBearer", format: "JWT"))
    
    userProtected.post(":forumPostID", use: self.create)
      .openAPI(
        tags: "Reports", "Forum", "Posts",
        summary: "Create",
        description: "Create a forum post report",
        body: .type(CreateForumPostReportDTO.self),
        response: .type(GetForumPostReportDTO.self)
      )
    
    modProtected.patch("process", ":reportID", use: self.process)
      .openAPI(
        tags: "Reports", "Forum", "Posts",
        summary: "Process",
        description: "Mark a forum post report as processed by a moderator",
        body: .type(ProcessForumPostReportDTO.self),
        response: .type(GetForumPostReportDTO.self)
      )
  }
  
  @Sendable
  func create(req: Request) async throws -> GetForumPostReportDTO {
    try CreateForumPostReportDTO.validate(content: req)
    let dto = try req.content.decode(CreateForumPostReportDTO.self)
    let userID = try await req.requireUser().requireID()
    let forumPostID = try req.parameters.require("forumPostID", as: UUID.self)
    
    guard try await ForumPost.find(forumPostID, on: req.db) != nil else {
      throw Abort(.notFound, reason: "ForumPost not found")
    }
    
    let report = ForumPostReport(from: dto, userID: userID, forumPostID: forumPostID)
    try await report.save(on: req.db)
        
    return try GetForumPostReportDTO(from: await findReport(id: report.requireID(), on: req.db))
  }
  
  @Sendable
  func process(req: Request) async throws -> GetForumPostReportDTO {
    try ProcessForumPostReportDTO.validate(content: req)
    let dto = try req.content.decode(ProcessForumPostReportDTO.self)
    let reportID = try req.parameters.require("reportID", as: UUID.self)
    
    guard let report = try await ForumPostReport.find(reportID, on: req.db) else {
      throw Abort(.notFound, reason: "ForumPostReport not found")
    }
    
    guard report.processDate == nil else {
      throw Abort(.badRequest, reason: "Report already processed")
    }
    
    report.process(with: dto)
    try await report.save(on: req.db)
    
    return try GetForumPostReportDTO(from: await findReport(id: report.requireID(), on: req.db))
  }
  
  private func findReport(id: UUID, on db: any Database) async throws -> ForumPostReport {
    let report = try await ForumPostReport.query(on: db)
      .filter(\.$id == id)
      .with(\.$forumPost, { $0.with(\.$user) })
      .with(\.$user)
      .with(\.$moderationCategory)
      .first()
    return try returnOrFail(report)
  }
}
