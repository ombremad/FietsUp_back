//
//  CycleColorController.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 29/04/2026.
//

import Vapor
import Fluent

struct CycleColorController: RouteCollection {
  func boot(routes: any RoutesBuilder) throws {
    
    let request = routes.grouped("cycles", "colors")
    
    let adminProtected = request
      .grouped(JWTMiddleware(), RequireAdminLevelMiddleware(minimumLevel: 2))
      .groupedOpenAPI(auth: .bearer(id: "AdminBearer", format: "JWT"))
    
    adminProtected.post(use: self.create)
      .openAPI(
        tags: "Cycles", "Colors",
        summary: "Create",
        description: "Create a cycle color",
        body: .type(CreateCycleColorDTO.self),
        response: .type(GetCycleColorDTO.self)
      )
    
    adminProtected.get(use: self.getAll)
      .openAPI(
        tags: "Cycles", "Colors",
        summary: "List",
        description: "List all available cycle colors",
        response: .type([GetCycleColorDTO].self)
      )
    
    adminProtected.patch(":id", use: self.patchByID)
      .openAPI(
        tags: "Cycles", "Colors",
        summary: "Patch",
        description: "Find and patch an existing cycle color by id",
        path: .type(UUID.self),
        body: .type(PatchCycleColorDTO.self),
        response: .type(GetCycleColorDTO.self)
      )
  }
  
  @Sendable
  func create(req: Request) async throws -> GetCycleColorDTO {
    try CreateCycleColorDTO.validate(content: req)
    let dto = try req.content.decode(CreateCycleColorDTO.self)
    
    let cycleColor = CycleColor(from: dto)
    try await cycleColor.save(on: req.db)
    return try GetCycleColorDTO(from: cycleColor)
  }
  
  @Sendable
  func getAll(req: Request) async throws -> [GetCycleColorDTO] {
    try await CycleColor.query(on: req.db)
      .sort(\.$color, .descending)
      .all()
      .map { cycleColor in try GetCycleColorDTO(from: cycleColor) }
  }
  
  @Sendable
  func patchByID(req: Request) async throws -> GetCycleColorDTO {
    let id = try req.parameters.require("id", as: UUID.self)
    let cycleColor = try await find(id: id, on: req.db)
    
    try PatchCycleColorDTO.validate(content: req)
    let dto = try req.content.decode(PatchCycleColorDTO.self)
    cycleColor.patch(with: dto)
    try await cycleColor.save(on: req.db)
    return try GetCycleColorDTO(from: cycleColor)
  }
  
  private func find(id: UUID, on db: any Database) async throws -> CycleColor {
    let cycleColor = try await CycleColor.query(on: db)
      .filter(\.$id == id)
      .first()
    return try returnOrFail(cycleColor)
  }
}
