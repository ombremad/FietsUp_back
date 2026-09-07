//
//  CreatePlaceCategoryDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 25/03/2026.
//

import Vapor

struct CreatePlaceCategoryDTO: Content {
  var name: String
  var iconName: String
}

extension CreatePlaceCategoryDTO: Validatable {
  static func validations(_ validations: inout Validations) {
    validations.add("name", as: String.self, is: .count(1...50))
    validations.add("iconName", as: String.self, is: .count(1...100) && .ascii)
  }
}
