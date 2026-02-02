//
//  UserMapper.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 02/02/2026.
//

import Vapor
import Fluent
import JWT

struct UserMapper {
    static func toNewModel(from dto: CreateUserDTO) throws -> User {
        let model = User()
        
        model.id = UUID()
        
        // user provided
        model.firstName = dto.firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        model.lastName = dto.lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        model.nickname = dto.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        model.email = dto.email.trimmingCharacters(in: .whitespacesAndNewlines)
        model.password = try Bcrypt.hash(dto.password)
        model.bio = dto.bio ?? nil
        
        // defaults
        model.creationDate = .now
        model.banEndDate = nil
        model.adminRights = 0
        model.streak = 0        
        
        return model
    }
    
    static func toDTO(from model: User) throws -> GetUserDTO {
        return GetUserDTO(
            id: model.id!,
            firstName: model.firstName,
            lastName: model.lastName,
            nickname: model.nickname,
            email: model.email,
            bio: model.bio,
            streak: model.streak,
        )
    }
}
