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
        let users = routes.grouped("users")
        let protected = users.grouped(JWTMiddleware()).groupedOpenAPI(auth: .bearer())
        
        users.post("signup", use: self.create)
            .openAPI(
                summary: "Create user",
                description: "Create a new user",
                body: .type(CreateUserDTO.self),
                response: .type(GetUserDTO.self)
            )
            .openAPINoAuth()
        
        users.post("login", use: self.login)
            .openAPI(
                summary: "Login user",
                description: "Log an existing user in",
                body: .type(LoginUserDTO.self),
                response: .type(GetTokenDTO.self)
            )
            .openAPINoAuth()
        
        protected.get("test", use: self.test)
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
    func test(req: Request) async throws -> String {
        return "It works lol"
    }
}
