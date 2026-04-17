//
//  DangerCommentReportController.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 17/04/2026.
//

import Vapor
import Fluent

struct DangerCommentReportController: RouteCollection {
  func boot(routes: any RoutesBuilder) throws {
    
    let request = routes.grouped("reports", "dangers", "comments")
    
    let userProtected = request
      .grouped(JWTMiddleware())
      .groupedOpenAPI(auth: .bearer(id: "BearerAuth", format: "JWT"))
    
    let modProtected = request
      .grouped(JWTMiddleware(), RequireAdminLevelMiddleware(minimumLevel: 1))
      .groupedOpenAPI(auth: .bearer(id: "ModBearer", format: "JWT"))
    
    userProtected.post(":dangerCommentID", use: self.create)
      .openAPI(
        tags: "Reports", "Dangers", "Comments",
        summary: "Create",
        description: "Create a danger comment report",
        body: .type(CreateDangerCommentReportDTO.self),
        response: .type(GetDangerCommentReportDTO.self)
      )
    
    modProtected.get("pending", use: self.pending)
      .openAPI(
        tags: "Reports", "Dangers", "Comments",
        summary: "Index",
        description: "See pending danger comments reports",
        response: .type([GetDangerCommentReportDTO].self)
      )
    
    modProtected.patch("process", ":reportID", use: self.process)
      .openAPI(
        tags: "Reports", "Dangers", "Comments",
        summary: "Process",
        description: "Mark a danger comment report as processed by a moderator",
        body: .type(ProcessDangerCommentReportDTO.self),
        response: .type(GetDangerCommentReportDTO.self)
      )
  }
  
  @Sendable
  func create(req: Request) async throws -> GetDangerCommentReportDTO {
    let dto = try req.content.decode(CreateDangerCommentReportDTO.self)
    let userID = try await req.requireUser().requireID()
    let dangerCommentID = try req.parameters.require("dangerCommentID", as: UUID.self)
    
    guard try await DangerComment.find(dangerCommentID, on: req.db) != nil else {
      throw Abort(.notFound, reason: "DangerComment not found")
    }
    
    let report = DangerCommentReport(from: dto, userID: userID, dangerCommentID: dangerCommentID)
    try await report.save(on: req.db)
    
    return try GetDangerCommentReportDTO(from: await findReport(id: report.requireID(), on: req.db))
  }
  
  @Sendable
  func pending(req: Request) async throws -> [GetDangerCommentReportDTO] {
    let pendingReports = try await DangerCommentReport.query(on: req.db)
      .filter(\.$processDate == nil)
      .sort(\.$creationDate, .ascending)
      .with(\.$dangerComment, { $0.with(\.$user) })
      .with(\.$user)
      .with(\.$moderationCategory)
      .all()
    
    return try pendingReports.map { try GetDangerCommentReportDTO(from: $0) }
  }
  
  @Sendable
  func process(req: Request) async throws -> GetDangerCommentReportDTO {
    try ProcessDangerCommentReportDTO.validate(content: req)
    let dto = try req.content.decode(ProcessDangerCommentReportDTO.self)
    let reportID = try req.parameters.require("reportID", as: UUID.self)
    
    guard let report = try await DangerCommentReport.find(reportID, on: req.db) else {
      throw Abort(.notFound, reason: "DangerCommentReport not found")
    }
    
    guard report.processDate == nil else {
      throw Abort(.badRequest, reason: "Report already processed")
    }
    
    report.process(with: dto)
    try await report.save(on: req.db)
    
    return try GetDangerCommentReportDTO(from: await findReport(id: report.requireID(), on: req.db))
  }
  
  private func findReport(id: UUID, on db: any Database) async throws -> DangerCommentReport {
    let report = try await DangerCommentReport.query(on: db)
      .filter(\.$id == id)
      .with(\.$dangerComment, { $0.with(\.$user) })
      .with(\.$user)
      .with(\.$moderationCategory)
      .first()
    return try returnOrFail(report)
  }
}
