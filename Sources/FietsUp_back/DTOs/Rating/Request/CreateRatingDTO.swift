//
//  CreateRatingDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 12/09/2026.
//

import Vapor

struct CreateRatingDTO: Content {
  var note: Int
}

extension CreateRatingDTO: Validatable {
  static func validations(_ validations: inout Validations) {
    validations.add("note", as: Int.self, is: .range(1...5))
  }
}
