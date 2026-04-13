//
//  DangerCategoryController.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 26/03/2026.
//

import Vapor
import Fluent

struct DangerCategoryController: RouteCollection {
  func boot(routes: any RoutesBuilder) throws {
    
    let request = routes.grouped("dangers", "categories")
    
    let userProtected = request
      .grouped(JWTMiddleware())
      .groupedOpenAPI(auth: .bearer(id: "BearerAuth", format: "JWT"))
    
    let adminProtected = request
      .grouped(JWTMiddleware(), RequireAdminLevelMiddleware(minimumLevel: 2))
      .groupedOpenAPI(auth: .bearer(id: "AdminBearer", format: "JWT"))
    
    adminProtected.post(use: self.create)
      .openAPI(
        tags: "Dangers", "Categories",
        summary: "Create",
        description: "Create a danger category",
        body: .type(CreateDangerCategoryDTO.self),
        response: .type(GetDangerCategoryDTO.self)
      )
    
    adminProtected.get(use: self.getAll)
      .openAPI(
        tags: "Dangers", "Categories",
        summary: "List",
        description: "List all available danger categories",
        response: .type([GetDangerCategoryDTO].self)
      )
    
    adminProtected.patch(":categoryID", use: self.patchByID)
      .openAPI(
        tags: "Dangers", "Categories",
        summary: "Patch",
        description: "Find and patch an existing danger category by id",
        path: .type(UUID.self),
        body: .type(PatchDangerCategoryDTO.self),
        response: .type(GetDangerCategoryDTO.self)
      )
    
    let posts = userProtected.grouped(":categoryID", "posts")
    try DangerPostController().boot(routes: posts)
  }
  
  @Sendable
  func create(req: Request) async throws -> GetDangerCategoryDTO {
    try CreateDangerCategoryDTO.validate(content: req)
    let dto = try req.content.decode(CreateDangerCategoryDTO.self)
    
    let dangerCategory = DangerCategory(from: dto)
    try await dangerCategory.save(on: req.db)
    return try GetDangerCategoryDTO(from: dangerCategory)
  }
  
  @Sendable
  func getAll(req: Request) async throws -> [GetDangerCategoryDTO] {
    try await DangerCategory.query(on: req.db)
      .sort(\.$name)
      .all()
      .map { category in try GetDangerCategoryDTO(from: category) }
  }
  
  @Sendable
  func patchByID(req: Request) async throws -> GetDangerCategoryDTO {
    let id = try req.parameters.require("categoryID", as: UUID.self)
    let category = try await find(id: id, on: req.db)
    
    try PatchDangerCategoryDTO.validate(content: req)
    let dto = try req.content.decode(PatchDangerCategoryDTO.self)
    category.patch(with: dto)
    try await category.save(on: req.db)
    return try GetDangerCategoryDTO(from: category)
  }
  
  private func find(id: UUID, on db: any Database) async throws -> DangerCategory {
    guard
      let category = try await DangerCategory.query(on: db)
        .filter(\.$id == id)
        .first()
    else {
      throw Abort(.notFound)
    }
    return category
  }
}
