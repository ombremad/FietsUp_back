//
//  PatchDangerCategoryDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 26/03/2026.
//

import Vapor

struct PatchDangerCategoryDTO: Content {
  var name: String?
  var iconName: String?
}

extension PatchDangerCategoryDTO: Validatable {
  static func validations(_ validations: inout Validations) {
    validations.add("name", as: String.self, is: .count(1...50), required: false)
    validations.add("iconName", as: String.self, is: .count(1...100) && .ascii, required: false)
  }
}
