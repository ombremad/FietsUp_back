//
//  PatchUserAdminDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 15/07/2026.
//

import Vapor

struct PatchUserAdminDTO: Content {
  var email: String?
  var nickname: String?
  var firstName: String?
  var lastName: String?
  var bio: String?
  var adminRights: Int?
}

extension PatchUserAdminDTO: Validatable {
  static func validations(_ validations: inout Validations) {
    validations.add("email", as: String.self, is: .count(1...100) && .internationalEmail, required: false)
    validations.add("nickname", as: String.self, is: .count(1...50) && .ascii, required: false)
    validations.add("firstName", as: String.self, is: .count(1...50), required: false)
    validations.add("lastName", as: String.self, is: .count(1...50), required: false)
    validations.add("bio", as: String.self, is: .count(0...500), required: false)
    validations.add("adminRights", as: Int.self, is: .range(0...2), required: false)
  }
}
