//
//  PatchModerationCategoryDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 26/03/2026.
//

import Vapor

struct PatchModerationCategoryDTO: Content {
  var name: String?
}

extension PatchModerationCategoryDTO: Validatable {
  static func validations(_ validations: inout Validations) {
    validations.add("name", as: String.self, is: .count(1...100), required: false)
  }
}
