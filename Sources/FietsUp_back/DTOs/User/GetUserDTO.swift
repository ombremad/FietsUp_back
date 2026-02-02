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
