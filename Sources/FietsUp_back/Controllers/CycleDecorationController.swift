//
//  CycleDecorationController.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 29/04/2026.
//

import Vapor
import Fluent

struct CycleDecorationController: RouteCollection {
  func boot(routes: any RoutesBuilder) throws {
    
    let request = routes.grouped("cycles", "decorations")
    
    let adminProtected = request
      .grouped(JWTMiddleware(), RequireAdminLevelMiddleware(minimumLevel: 2))
      .groupedOpenAPI(auth: .bearer(id: "AdminBearer", format: "JWT"))
    
    adminProtected.post(use: self.create)
      .openAPI(
        tags: "Cycles", "Decorations",
        summary: "Create",
        description: "Create a cycle decoration",
        body: .type(CreateCycleDecorationDTO.self),
        response: .type(GetCycleDecorationDTO.self)
      )
    
    adminProtected.get(use: self.getAll)
      .openAPI(
        tags: "Cycles", "Decoration",
        summary: "List",
        description: "List all available cycle decorations",
        response: .type([GetCycleDecorationDTO].self)
      )
    
    adminProtected.patch(":id", use: self.patchByID)
      .openAPI(
        tags: "Cycles", "Decoration",
        summary: "Patch",
        description: "Find and patch an existing cycle decoration by id",
        path: .type(UUID.self),
        body: .type(PatchCycleDecorationDTO.self),
        response: .type(GetCycleDecorationDTO.self)
      )
  }
  
  @Sendable
  func create(req: Request) async throws -> GetCycleDecorationDTO {
    try CreateCycleDecorationDTO.validate(content: req)
    let dto = try req.content.decode(CreateCycleDecorationDTO.self)
    
    let cycleDecoration = CycleDecoration(from: dto)
    try await cycleDecoration.save(on: req.db)
    return try GetCycleDecorationDTO(from: cycleDecoration)
  }
  
  @Sendable
  func getAll(req: Request) async throws -> [GetCycleDecorationDTO] {
    try await CycleDecoration.query(on: req.db)
      .sort(\.$name)
      .all()
      .map { cycleDecoration in try GetCycleDecorationDTO(from: cycleDecoration) }
  }
  
  @Sendable
  func patchByID(req: Request) async throws -> GetCycleDecorationDTO {
    let id = try req.parameters.require("id", as: UUID.self)
    let cycleDecoration = try await find(id: id, on: req.db)
    
    try PatchCycleDecorationDTO.validate(content: req)
    let dto = try req.content.decode(PatchCycleDecorationDTO.self)
    cycleDecoration.patch(with: dto)
    try await cycleDecoration.save(on: req.db)
    return try GetCycleDecorationDTO(from: cycleDecoration)
  }
  
  private func find(id: UUID, on db: any Database) async throws -> CycleDecoration {
    let cycleDecoration = try await CycleDecoration.query(on: db)
      .filter(\.$id == id)
      .first()
    return try returnOrFail(cycleDecoration)
  }
}
