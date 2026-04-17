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
    
    userProtected.get(use: self.get)
      .openAPI(
        tags: "Dashboard",
        summary: "Get",
        description: "Get dashboard",
        response: .type(GetDashboardDTO.self)
      )
  }
  
  @Sendable
  func get(req: Request) async throws -> GetDashboardDTO {
    // TODO: complete dashboard
    let user = try await req.requireUser()
    return try GetDashboardDTO(user: user)
  }
}
