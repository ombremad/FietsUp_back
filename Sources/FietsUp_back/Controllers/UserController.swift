//
//  UserController.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 02/02/2026.
//

import Fluent
import Vapor
import JWT

struct UserController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        
        let request = routes.grouped("users")
        let userProtected = request
            .grouped(JWTMiddleware())
            .groupedOpenAPI(auth: .bearer(id: "BearerAuth", format: "JWT"))
        let adminProtected = request
            .grouped(JWTMiddleware(), RequireAdminLevelMiddleware(minimumLevel: 2))
            .groupedOpenAPI(auth: .bearer(id: "AdminBearer", format: "JWT"))
        
        request.post("signup", use: self.create)
            .openAPI(
                summary: "Create user",
                description: "Create a new user",
                body: .type(CreateUserDTO.self),
                response: .type(GetUserDTO.self)
            )
            .openAPINoAuth()
        
        request.post("login", use: self.login)
            .openAPI(
                summary: "Login user",
                description: "Log an existing user in",
                body: .type(LoginUserDTO.self),
                response: .type(GetTokenDTO.self)
            )
            .openAPINoAuth()
        
        adminProtected.get(use: self.getAll)
            .openAPI(
                summary: "List all users",
                description: "List all existing users",
                response: .type([GetUserDTO].self)
            )
        
        adminProtected.get(":userId", use: self.getById)
            .openAPI(
                summary: "Find one user",
                description: "Find an existing user by id",
                path: .type(UUID.self),
                response: .type(GetUserDTO.self)
            )
        
        adminProtected.patch(":userId", use: self.patchById)
            .openAPI(
                summary: "Patch one user",
                description: "Find and patch an existing user by id",
                path: .type(UUID.self),
                body: .type(PatchUserDTO.self),
                response: .type(GetUserDTO.self)
            )
        
        adminProtected.delete(":userId", use: self.deleteById)
            .openAPI(
                summary: "Delete one user",
                description: "Permanently delete an existing user by id",
                path: .type(UUID.self),
                response: .type(HTTPStatus.self)
            )
        
        userProtected.get("me", use: self.getMe)
            .openAPI(
                summary: "Get me",
                description: "Get current user",
                response: .type(GetUserDTO.self)
            )
        
        userProtected.patch("me", use: self.patchMe)
            .openAPI(
                summary: "Patch me",
                description: "Patch current user",
                body: .type(PatchUserDTO.self),
                response: .type(GetUserDTO.self)
            )
        
        userProtected.delete("me", use: self.deleteMe)
            .openAPI(
                summary: "Delete me",
                description: "Permanently delete current user",
                response: .type(HTTPStatus.self)
            )
    }
    
    @Sendable
    func create(req: Request) async throws -> GetUserDTO {
        try CreateUserDTO.validate(content: req)
        let userDTO = try req.content.decode(CreateUserDTO.self)
        
        let user = try User(from: userDTO)
        try await user.save(on: req.db)
        return try GetUserDTO(from: user)
    }
    
    @Sendable
    func login(req: Request) async throws -> GetTokenDTO {
        try LoginUserDTO.validate(content: req)
        let userData = try req.content.decode(LoginUserDTO.self)
        
        guard let user = try await User.query(on: req.db)
            .filter(\.$email == userData.email)
            .first() else {
            throw Abort(.unauthorized, reason: "Incorrect login. Check your email and password.")
        }
        
        guard try Bcrypt.verify(userData.password, created: user.password) else {
            throw Abort(.unauthorized, reason: "Incorrect login. Check your email and password.")
        }
        
        let payload = UserPayload(id: user.id!)
        let signer = JWTSigner.hs256(key: JWTConfig.shared.jwtSecret)
        let token = try signer.sign(payload)
        return GetTokenDTO(token)
    }
    
    @Sendable
    func getAll(req: Request) async throws -> [GetUserDTO] {
        try await User.query(on: req.db)
            .sort(\.$email)
            .all()
            .map { user in try GetUserDTO(from: user) }
    }
    
    @Sendable
    func getById(req: Request) async throws -> GetUserDTO {
        let userId = try req.parameters.require("userId", as: UUID.self)
        guard let user = try await User.query(on: req.db)
            .filter(\.$id == userId)
            .first() else {
            throw Abort(.notFound)
        }
        return try GetUserDTO(from: user)
    }
    
    @Sendable
    func getMe(req: Request) async throws -> GetUserDTO {
        let payload = try req.auth.require(UserPayload.self)
        guard let user = try await User.query(on: req.db)
            .filter(\.$id == payload.id)
            .first() else {
            throw Abort(.notFound)
        }
        return try GetUserDTO(from: user)
    }
    
    @Sendable
    func patchById(req: Request) async throws -> GetUserDTO {
        try PatchUserDTO.validate(content: req)
        let patchDTO = try req.content.decode(PatchUserDTO.self)
        let userId = try req.parameters.require("userId", as: UUID.self)

        guard let user = try await User.query(on: req.db)
            .filter(\.$id == userId)
            .first() else {
            throw Abort(.notFound)
        }
        
        user.apply(patchDTO)
        try await user.save(on: req.db)
        return try GetUserDTO(from: user)
    }
    
    @Sendable
    func patchMe(req: Request) async throws -> GetUserDTO {
        try PatchUserDTO.validate(content: req)
        let patchDTO = try req.content.decode(PatchUserDTO.self)
        let payload = try req.auth.require(UserPayload.self)
        
        guard let user = try await User.query(on: req.db)
            .filter(\.$id == payload.id)
            .first() else {
            throw Abort(.notFound)
        }
        
        user.apply(patchDTO)
        try await user.save(on: req.db)
        return try GetUserDTO(from: user)
    }
    
    @Sendable
    func deleteById(req: Request) async throws -> HTTPStatus {
        let userId = try req.parameters.require("userId", as: UUID.self)
        
        guard let user = try await User.query(on: req.db)
            .filter(\.$id == userId)
            .first() else {
            throw Abort(.notFound)
        }

        try await user.delete(on: req.db)
        return .noContent
    }
    
    @Sendable
    func deleteMe(req: Request) async throws -> HTTPStatus {
        let payload = try req.auth.require(UserPayload.self)

        guard let user = try await User.query(on: req.db)
            .filter(\.$id == payload.id)
            .first() else {
            throw Abort(.notFound)
        }
        
        try await user.delete(on: req.db)
        return .noContent
    }
}
