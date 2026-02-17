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
        
        adminProtected.get(use: self.get)
            .openAPI(
                summary: "List all users",
                description: "List all existing users",
                response: .type([GetUserDTO].self)
            )
    }
    
    @Sendable
    func create(req: Request) async throws -> GetUserDTO {
        try CreateUserDTO.validate(content: req)
        let createDTO = try req.content.decode(CreateUserDTO.self)
        
        let user = try UserMapper.toNewModel(from: createDTO)
        try await user.save(on: req.db)
        return try UserMapper.toDTO(from: user)
    }
    
    @Sendable
    func login(req: Request) async throws -> GetTokenDTO {
        let userData = try req.content.decode(LoginUserDTO.self)
        
        // Search user by email
        guard let user = try await User.query(on: req.db)
            .filter(\.$email == userData.email)
            .first() else {
            throw Abort(.unauthorized, reason: "This user does not exist.")
        }
        
        // Check password
        guard try Bcrypt.verify(userData.password, created: user.password) else {
            throw Abort(.unauthorized, reason: "Incorrect password.")
        }
        
        // Create JWT and return token
        let payload = UserPayload(id: user.id!)
        let signer = JWTSigner.hs256(key: JWTConfig.shared.jwtSecret)
        let token = try signer.sign(payload)
        return GetTokenDTO(token)
    }
    
    @Sendable
    func get(req: Request) async throws -> [GetUserDTO] {
        let payload = try req.auth.require(UserPayload.self)
        guard let user = try await User.find(payload.id, on: req.db) else {
            throw Abort(.notFound)
        }
        guard user.adminRights >= 2 else {
            throw Abort(.forbidden)
        }

        return try await User.query(on: req.db)
            .sort(\.$email)
            .all()
            .map { try UserMapper.toDTO(from: $0) }
    }
}
