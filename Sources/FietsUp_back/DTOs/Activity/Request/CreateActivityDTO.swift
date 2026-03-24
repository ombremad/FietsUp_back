//
//  CreateActivityDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 24/03/2026.
//

import Fluent
import Vapor

struct CreateActivityDTO: Content {
  var startDate: Date
  var endDate: Date
  var distance: Int
}

extension CreateActivityDTO: Validatable {
  static func validations(_ validations: inout Validations) {
    validations.add(
      "startDate", as: Date.self,
      is: .valid,
    )
    validations.add(
      "endDate", as: Date.self,
      is: .valid,
    )
    validations.add(
      "distance", as: Int.self,
      is: .range(1...720000)
    )
  }
}
