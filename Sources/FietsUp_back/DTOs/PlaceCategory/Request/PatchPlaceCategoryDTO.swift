//
//  PatchPlaceCategoryDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 25/03/2026.
//

import Vapor

struct PatchPlaceCategoryDTO: Content {
  var name: String?
  var iconName: String?
}

extension PatchPlaceCategoryDTO: Validatable {
  static func validations(_ validations: inout Validations) {
    validations.add("name", as: String.self, is: .count(1...50), required: false)
    validations.add("iconName", as: String.self, is: .count(1...100) && .ascii, required: false)
  }
}
