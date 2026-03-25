//
//  PatchUserDto.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 02/02/2026.
//

import Vapor

struct PatchUserDTO: Content {
  var firstName: String?
  var lastName: String?
  var nickname: String?
  var bio: String??
}

// Make ?? variables nullable in the patch
extension PatchUserDTO {
  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    firstName = try container.decodeIfPresent(String.self, forKey: .firstName)
    lastName = try container.decodeIfPresent(String.self, forKey: .lastName)
    nickname = try container.decodeIfPresent(String.self, forKey: .nickname)
    bio = try container.decodeNullablePatchVariable(String.self, forKey: .bio)
  }
}

extension PatchUserDTO: Validatable {
  static func validations(_ validations: inout Validations) {
    validations.add("firstName", as: String.self, is: .count(1...50), required: false)
    validations.add("lastName", as: String.self, is: .count(1...50), required: false)
    validations.add("nickname", as: String.self, is: .count(1...50) && .ascii, required: false)
    validations.add("bio", as: String.self, is: .count(1...500), required: false)
  }
}
