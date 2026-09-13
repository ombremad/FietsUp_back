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
  var bio: String?
  var cycleTypeId: UUID?
  var cycleColorId: UUID?
  var cycleDecorationId: UUID?
}

extension PatchUserDTO: Validatable {
  static func validations(_ validations: inout Validations) {
    validations.add("firstName", as: String.self, is: .count(1...50), required: false)
    validations.add("lastName", as: String.self, is: .count(1...50), required: false)
    validations.add("nickname", as: String.self, is: .count(1...50) && .ascii, required: false)
    validations.add("bio", as: String.self, is: .count(0...500), required: false)
  }
}
