//
//  PatchUserPasswordDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 12/05/2026.
//

import Vapor

struct PatchUserPasswordDTO: Content {
  var oldPassword: String
  var newPassword: String
}

extension PatchUserPasswordDTO: Validatable {
  static func validations(_ validations: inout Validations) {
    validations.add("oldPassword", as: String.self, is: .securePassword)
    validations.add("newPassword", as: String.self, is: .securePassword)
  }
}
