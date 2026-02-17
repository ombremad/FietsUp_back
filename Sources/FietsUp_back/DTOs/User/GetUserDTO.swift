//
//  GetUserDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 02/02/2026.
//

import Vapor
import Fluent

struct GetUserDTO: Content {
    var id: UUID
    var firstName: String
    var lastName: String
    var nickname: String
    var email: String
    var bio: String?
    var streak: Int
}

extension GetUserDTO {
    init(from model: User) throws {
        self.init(
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
