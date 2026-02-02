//
//  CreateUserDto.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 02/02/2026.
//

import Vapor
import Fluent

struct CreateUserDTO: Content {
    var firstName: String
    var lastName: String
    var nickname: String
    var email: String
    var password: String
    var bio: String?
}

extension CreateUserDTO: Validatable {
    static func validations(_ validations: inout Validations) {
        
        validations.add(
            "firstName", as: String.self,
            is: .count(1...50)
        )
        validations.add(
            "lastName", as: String.self,
            is: .count(1...50)
        )
        validations.add(
            "nickname", as: String.self,
            is: .count(1...50) && .alphanumeric
        )
        validations.add(
            "email", as: String.self,
            is: .email
        )
        validations.add(
            "password", as: String.self,
            is: .securePassword
        )
        validations.add(
            "bio", as: String?.self,
            is: .nil || .count(1...500),
            required: false
        )
    }
}
