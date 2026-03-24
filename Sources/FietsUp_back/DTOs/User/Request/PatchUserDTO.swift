//
//  PatchUserDto.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 02/02/2026.
//

import Vapor
import Fluent

struct PatchUserDTO: Content {
    var firstName: String?
    var lastName: String?
    var nickname: String?
    var bio: String?
}

extension PatchUserDTO: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add(
            "firstName", as: String.self,
            is: .count(1...50),
            required: false
        )
        validations.add(
            "lastName", as: String.self,
            is: .count(1...50),
            required: false
        )
        validations.add(
            "nickname", as: String.self,
            is: .count(1...50) && .alphanumeric,
            required: false
        )
        validations.add(
            "bio", as: String?.self,
            is: .nil || .count(1...500),
            required: false
        )
    }
}

extension User {
    func apply(_ dto: PatchUserDTO) {
        if let firstName = dto.firstName { self.firstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines) }
        if let lastName = dto.lastName { self.lastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines) }
        if let nickname = dto.nickname { self.nickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines) }
        if let bio = dto.bio { self.bio = bio }
    }
}
