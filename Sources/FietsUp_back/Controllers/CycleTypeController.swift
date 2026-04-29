//
//  CycleTypeController.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 29/04/2026.
//

import Vapor
import Fluent

struct CycleTypeController: RouteCollection {
  func boot(routes: any RoutesBuilder) throws {
    
    let request = routes.grouped("cycles", "types")
    
    let adminProtected = request
      .grouped(JWTMiddleware(), RequireAdminLevelMiddleware(minimumLevel: 2))
      .groupedOpenAPI(auth: .bearer(id: "AdminBearer", format: "JWT"))
    
    adminProtected.post(use: self.create)
      .openAPI(
        tags: "Cycles", "Types",
        summary: "Create",
        description: "Create a cycle type",
        body: .type(CreateCycleTypeDTO.self),
        response: .type(GetCycleTypeDTO.self)
      )
    
    adminProtected.get(use: self.getAll)
      .openAPI(
        tags: "Cycles", "Types",
        summary: "List",
        description: "List all available cycle types",
        response: .type([GetCycleTypeDTO].self)
      )
    
    adminProtected.patch(":id", use: self.patchByID)
      .openAPI(
        tags: "Cycles", "Types",
        summary: "Patch",
        description: "Find and patch an existing cycle type by id",
        path: .type(UUID.self),
        body: .type(PatchCycleTypeDTO.self),
        response: .type(GetCycleTypeDTO.self)
      )
  }
  
  @Sendable
  func create(req: Request) async throws -> GetCycleTypeDTO {
    try CreateCycleTypeDTO.validate(content: req)
    let dto = try req.content.decode(CreateCycleTypeDTO.self)
    
    let cycleType = CycleType(from: dto)
    try await cycleType.save(on: req.db)
    return try GetCycleTypeDTO(from: cycleType)
  }
  
  @Sendable
  func getAll(req: Request) async throws -> [GetCycleTypeDTO] {
    try await CycleType.query(on: req.db)
      .sort(\.$name)
      .all()
      .map { cycleType in try GetCycleTypeDTO(from: cycleType) }
  }
  
  @Sendable
  func patchByID(req: Request) async throws -> GetCycleTypeDTO {
    let id = try req.parameters.require("id", as: UUID.self)
    let cycleType = try await find(id: id, on: req.db)
    
    try PatchCycleTypeDTO.validate(content: req)
    let dto = try req.content.decode(PatchCycleTypeDTO.self)
    cycleType.patch(with: dto)
    try await cycleType.save(on: req.db)
    return try GetCycleTypeDTO(from: cycleType)
  }
  
  private func find(id: UUID, on db: any Database) async throws -> CycleType {
    let cycleType = try await CycleType.query(on: db)
      .filter(\.$id == id)
      .first()
    return try returnOrFail(cycleType)
  }
}
