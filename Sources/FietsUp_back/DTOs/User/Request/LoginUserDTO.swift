//
//  LoginUserDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 17/02/2026.
//

import Vapor
import Fluent

struct LoginUserDTO: Content {
    var email: String
    var password: String
}

extension LoginUserDTO: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add(
            "email", as: String.self,
            is: .email
        )
        validations.add(
            "password", as: String.self,
            is: .securePassword
        )
    }
}
