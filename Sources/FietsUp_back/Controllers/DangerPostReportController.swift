//
//  DangerPostReportController.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 17/04/2026.
//

import Vapor
import Fluent

struct DangerPostReportController: RouteCollection {
  func boot(routes: any RoutesBuilder) throws {
    
    let request = routes.grouped("reports", "dangers", "posts")
    
    let userProtected = request
      .grouped(JWTMiddleware())
      .groupedOpenAPI(auth: .bearer(id: "BearerAuth", format: "JWT"))
    
    let modProtected = request
      .grouped(JWTMiddleware(), RequireAdminLevelMiddleware(minimumLevel: 1))
      .groupedOpenAPI(auth: .bearer(id: "ModBearer", format: "JWT"))
    
    userProtected.post(":dangerPostID", use: self.create)
      .openAPI(
        tags: "Reports", "Dangers", "Posts",
        summary: "Create",
        description: "Create a danger post report",
        body: .type(CreateReportDTO.self),
        response: .type(GetDangerPostReportDTO.self)
      )
    
    modProtected.get("pending", use: self.pending)
      .openAPI(
        tags: "Reports", "Dangers", "Posts",
        summary: "Index",
        description: "See pending danger posts reports",
        response: .type([GetDangerPostReportDTO].self)
      )
    
    modProtected.patch("process", ":reportID", use: self.process)
      .openAPI(
        tags: "Reports", "Dangers", "Posts",
        summary: "Process",
        description: "Mark a danger post report as processed by a moderator",
        body: .type(ProcessReportDTO.self),
        response: .type(GetDangerPostReportDTO.self)
      )
  }
  
  @Sendable
  func create(req: Request) async throws -> GetDangerPostReportDTO {
    let dto = try req.content.decode(CreateReportDTO.self)
    let userID = try await req.requireUser().requireID()
    let dangerPostID = try req.parameters.require("dangerPostID", as: UUID.self)
    
    guard try await DangerPost.find(dangerPostID, on: req.db) != nil else {
      throw Abort(.notFound, reason: "DangerPost not found")
    }
    
    let report = DangerPostReport(from: dto, userID: userID, dangerPostID: dangerPostID)
    try await report.save(on: req.db)
    
    return try GetDangerPostReportDTO(from: await findReport(id: report.requireID(), on: req.db))
  }
  
  @Sendable
  func pending(req: Request) async throws -> [GetDangerPostReportDTO] {
    let pendingReports = try await DangerPostReport.query(on: req.db)
      .filter(\.$processDate == nil)
      .sort(\.$creationDate, .ascending)
      .with(\.$dangerPost, { $0.with(\.$user).with(\.$dangerCategory) })
      .with(\.$user)
      .with(\.$moderationCategory)
      .all()
    
    return try pendingReports.map { try GetDangerPostReportDTO(from: $0) }
  }
  
  @Sendable
  func process(req: Request) async throws -> GetDangerPostReportDTO {
    try ProcessReportDTO.validate(content: req)
    let dto = try req.content.decode(ProcessReportDTO.self)
    let reportID = try req.parameters.require("reportID", as: UUID.self)
    
    guard let report = try await DangerPostReport.find(reportID, on: req.db) else {
      throw Abort(.notFound, reason: "DangerPostReport not found")
    }
    
    guard report.processDate == nil else {
      throw Abort(.badRequest, reason: "Report already processed")
    }
    
    report.process(with: dto)
    try await report.save(on: req.db)
    
    return try GetDangerPostReportDTO(from: await findReport(id: report.requireID(), on: req.db))
  }
  
  private func findReport(id: UUID, on db: any Database) async throws -> DangerPostReport {
    let report = try await DangerPostReport.query(on: db)
      .filter(\.$id == id)
      .with(\.$dangerPost, { $0.with(\.$user).with(\.$dangerCategory) })
      .with(\.$user)
      .with(\.$moderationCategory)
      .first()
    return try returnOrFail(report)
  }
}
