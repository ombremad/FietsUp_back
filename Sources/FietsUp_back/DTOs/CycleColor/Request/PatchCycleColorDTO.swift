//
//  PatchCycleColorDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 29/04/2026.
//

import Vapor

struct PatchCycleColorDTO: Content {
  var name: String?
  var color: String?
}

extension PatchCycleColorDTO: Validatable {
  static func validations(_ validations: inout Validations) {
    validations.add("name", as: String.self, is: .count(1...50), required: false)
    validations.add("color", as: String.self, is: .count(6...6) && .pattern("^[0-9A-Fa-f]{6}$"), required: false)
  }
}
