//
//  WebUserController.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 20/07/2026.
//

import Fluent
import Vapor

struct WebUserController: RouteCollection {
  func boot(routes: any RoutesBuilder) throws {
    let users = routes
      .grouped("panel", "users")
      .grouped(PanelErrorMiddleware())
    let protected = users.grouped(PanelAuthMiddleware())
    
    protected.get(use: self.list)
    protected.get(":userID", use: self.detail)
    protected.post(":userID", use: self.update)
  }
  
  @Sendable
  func list(req: Request) async throws -> View {
    let page = try await User.query(on: req.db)
      .sort(\.$email)
      .paginate(for: req)
    
    return try await req.view.render("/panel/users/list", PageContext(page))
  }
  
  @Sendable
  func detail(req: Request) async throws -> View {
    let userID = try req.parameters.require("userID", as: UUID.self)
    guard let user = try await User.find(userID, on: req.db) else {
      throw Abort(.notFound)
    }
    return try await req.view.render("/panel/users/detail", ["user": user])
  }
  
  @Sendable
  func update(req: Request) async throws -> Response {
    let userID = try req.parameters.require("userID", as: UUID.self)
    guard let user = try await User.find(userID, on: req.db) else {
      throw Abort(.notFound)
    }
    
    try PatchUserAdminDTO.validate(content: req)
    let dto = try req.content.decode(PatchUserAdminDTO.self)
    
    user.patchAdmin(with: dto)
    try await user.save(on: req.db)
    
    return req.redirect(to: "/panel/users/\(userID)")
  }
}
