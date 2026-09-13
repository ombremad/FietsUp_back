//
//  CreateCycleTypeDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 29/04/2026.
//

import Vapor

struct CreateCycleTypeDTO: Content {
  var name: String
  var fileLink: String
}

extension CreateCycleTypeDTO: Validatable {
  static func validations(_ validations: inout Validations) {
    validations.add("name", as: String.self, is: .count(1...50))
    validations.add("fileLink", as: String.self, is: .count(1...100) && .url)
  }
}
