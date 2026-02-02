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
        let users = routes.grouped("users")
        
        users.post("signup", use: self.create)
    }
    
    @Sendable
    func create(req: Request) async throws -> GetUserDTO {
        try CreateUserDTO.validate(content: req)
        let createDTO = try req.content.decode(CreateUserDTO.self)
        
        let user = try UserMapper.toNewModel(from: createDTO)
        try await user.save(on: req.db)
        return try UserMapper.toDTO(from: user)
    }
}
