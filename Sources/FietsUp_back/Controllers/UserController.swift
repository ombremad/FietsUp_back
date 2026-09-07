//
//  UserController.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 02/02/2026.
//

import Fluent
import Vapor

struct UserController: RouteCollection {
  func boot(routes: any RoutesBuilder) throws {

    let request = routes.grouped("users")
    
    let userProtected = request
      .grouped(JWTMiddleware())
      .groupedOpenAPI(auth: .bearer(id: "BearerAuth", format: "JWT"))
    
    let modProtected = request
      .grouped(JWTMiddleware(), RequireAdminLevelMiddleware(minimumLevel: 1))
      .groupedOpenAPI(auth: .bearer(id: "ModBearer", format: "JWT"))
    
    let adminProtected = request
      .grouped(JWTMiddleware(), RequireAdminLevelMiddleware(minimumLevel: 2))
      .groupedOpenAPI(auth: .bearer(id: "AdminBearer", format: "JWT"))

    request.post("signup", use: self.create)
      .openAPI(
        tags: "Users", "auth",
        summary: "Signup",
        description: "Create a new user",
        body: .type(CreateUserDTO.self),
        response: .type(GetAuthDTO.self)
      )
      .openAPINoAuth()

    request.post("login", use: self.login)
      .openAPI(
        tags: "Users", "auth",
        summary: "Login",
        description: "Log an existing user in",
        body: .type(LoginUserDTO.self),
        response: .type(GetAuthDTO.self)
      )
      .openAPINoAuth()

    adminProtected.get(use: self.getAll)
      .openAPI(
        tags: "Users",
        summary: "List",
        description: "List all existing users",
        query: .type(QueryPageDTO.self),
        response: .type(Page<GetUserDTO>.self)
      )

    adminProtected.get(":userID", use: self.getByID)
      .openAPI(
        tags: "Users",
        summary: "Find",
        description: "Find an existing user by id",
        path: .type(UUID.self),
        response: .type(GetUserDTO.self)
      )

    adminProtected.patch(":userID", use: self.patchByID)
      .openAPI(
        tags: "Users",
        summary: "Patch",
        description: "Find and patch an existing user by id",
        path: .type(UUID.self),
        body: .type(PatchUserDTO.self),
        response: .type(GetUserDTO.self)
      )

    adminProtected.delete(":userID", use: self.deleteByID)
      .openAPI(
        tags: "Users",
        summary: "Delete",
        description: "Permanently delete an existing user by id",
        path: .type(UUID.self),
        response: .type(HTTPStatus.self)
      )
    
    modProtected.patch(":userID", "ban", use: self.banUserByID)
      .openAPI(
        tags: "Users",
        summary: "Ban",
        description: "Ban an existing user by id",
        path: .type(UUID.self),
        body: .type(BanUserDTO.self),
        response: .type(GetUserDTO.self)
      )
    
    adminProtected.delete(":userID", "ban", use: self.unbanUserByID)
      .openAPI(
        tags: "Users",
        summary: "Unban",
        description: "Unban an existing user by id",
        path: .type(UUID.self),
        response: .type(GetUserDTO.self)
      )

    userProtected.get("me", use: self.getMe)
      .openAPI(
        tags: "Users", "me",
        summary: "Get me",
        description: "Get current user",
        response: .type(GetUserDTO.self)
      )

    userProtected.patch("me", use: self.patchMe)
      .openAPI(
        tags: "Users", "me",
        summary: "Patch me",
        description: "Patch current user",
        body: .type(PatchUserDTO.self),
        response: .type(GetUserDTO.self)
      )
    
    userProtected.patch("me", "password", use: self.changeMyPassword)
      .openAPI(
        tags: "Users", "me",
        summary: "Change my password",
        description: "Change current user's password",
        body: .type(PatchUserPasswordDTO.self),
        response: .type(GetUserDTO.self)
      )
  }

  @Sendable
  func create(req: Request) async throws -> GetAuthDTO {
    try CreateUserDTO.validate(content: req)
    let dto = try req.content.decode(CreateUserDTO.self)

    let user = try User(from: dto)
    try await user.save(on: req.db)
    
    let userID = try user.requireID()
    let token = try JWTConfig.shared.sign(UserPayload(id: userID))
    return try GetAuthDTO(token: token, user: user)
  }

  @Sendable
  func login(req: Request) async throws -> GetAuthDTO {
    try LoginUserDTO.validate(content: req)
    let userData = try req.content.decode(LoginUserDTO.self)

    guard let user = try await User.query(on: req.db)
      .filter(\.$email == userData.email)
      .withCycle()
      .first()
    else {
      throw Abort(.unauthorized, reason: "Incorrect login. Check your email and password.")
    }

    guard try Bcrypt.verify(userData.password, created: user.password) else {
      throw Abort(.unauthorized, reason: "Incorrect login. Check your email and password.")
    }
    
    if let banEndDate = user.banEndDate, banEndDate >= .now {
      throw Abort(.unauthorized, reason: "User is banned until \(banEndDate.description)")
    }
    
    let userID = try user.requireID()
    let token = try JWTConfig.shared.sign(UserPayload(id: userID))
    return try GetAuthDTO(token: token, user: user)
  }

  @Sendable
  func getAll(req: Request) async throws -> Page<GetUserDTO> {
    try QueryPageDTO.validate(query: req)
    
    return try await User.query(on: req.db)
      .sort(\.$email)
      .paginate(for: req)
      .map { user in try GetUserDTO(from: user) }
  }

  @Sendable
  func getByID(req: Request) async throws -> GetUserDTO {
    let userID = try req.parameters.require("userID", as: UUID.self)
    let user = try await findUserWithCycle(id: userID, on: req.db)
    return try GetUserDTO(from: user)
  }

  @Sendable
  func getMe(req: Request) async throws -> GetUserDTO {
    let user = try await req.requireUserWithCycle()
    return try GetUserDTO(from: user)
  }

  @Sendable
  func patchByID(req: Request) async throws -> GetUserDTO {
    let userID = try req.parameters.require("userID", as: UUID.self)
    let user = try await findUserWithCycle(id: userID, on: req.db)
    
    try PatchUserAdminDTO.validate(content: req)
    let dto = try req.content.decode(PatchUserAdminDTO.self)
    
    user.patchAdmin(with: dto)
    try await user.save(on: req.db)
    
    let updated = try await findUserWithCycle(id: user.requireID(), on: req.db)
    return try GetUserDTO(from: updated)
  }

  @Sendable
  func patchMe(req: Request) async throws -> GetUserDTO {
    let user = try await req.requireUserWithCycle()
    
    try PatchUserDTO.validate(content: req)
    let dto = try req.content.decode(PatchUserDTO.self)
    
    user.patch(with: dto)
    try await user.save(on: req.db)
    
    let updated = try await findUserWithCycle(id: user.requireID(), on: req.db)
    return try GetUserDTO(from: updated)
  }
  
  @Sendable
  func changeMyPassword(req: Request) async throws -> GetUserDTO {
    try PatchUserPasswordDTO.validate(content: req)
    let dto = try req.content.decode(PatchUserPasswordDTO.self)
    let user = try req.requireUser()
    
    guard try Bcrypt.verify(dto.oldPassword, created: user.password) else {
      throw Abort(.forbidden, reason: "Incorrect password.")
    }
    
    try user.patchPassword(to: dto.newPassword)
    try await user.save(on: req.db)
    return try GetUserDTO(from: user)
  }

  @Sendable
  func deleteByID(req: Request) async throws -> HTTPStatus {
    let userID = try req.parameters.require("userID", as: UUID.self)
    let user = try await findUser(id: userID, on: req.db)
    return try await deleteUser(user, on: req.db)
  }
  
  @Sendable
  func banUserByID(req: Request) async throws -> GetUserDTO {
    let userID = try req.parameters.require("userID", as: UUID.self)
    let user = try await findUser(id: userID, on: req.db)
    
    let dto = try req.content.decode(BanUserDTO.self)
    user.ban(until: dto.banEndDate)
    try await user.save(on: req.db)
    
    let updated = try await findUserWithCycle(id: user.requireID(), on: req.db)
    return try GetUserDTO(from: updated)
  }
  
  @Sendable
  func unbanUserByID(req: Request) async throws -> GetUserDTO {
    let userID = try req.parameters.require("userID", as: UUID.self)
    let user = try await findUser(id: userID, on: req.db)
    
    user.unban()
    try await user.save(on: req.db)
    
    let updated = try await findUserWithCycle(id: user.requireID(), on: req.db)
    return try GetUserDTO(from: updated)
  }

  private func findUser(id: UUID, on db: any Database) async throws -> User {
    let user = try await User.query(on: db)
      .filter(\.$id == id)
      .first()
    return try returnOrFail(user)
  }
  
  private func findUserWithCycle(id: UUID, on db: any Database) async throws -> User {
    let user = try await User.query(on: db)
      .filter(\.$id == id)
      .withCycle()
      .first()
    return try returnOrFail(user)
  }

  private func deleteUser(_ user: User, on db: any Database) async throws -> HTTPStatus {
    try await user.delete(on: db)
    return .noContent
  }
}
