//
//  CreateReportDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 17/04/2026.
//

import Vapor

struct CreateReportDTO: Content {
  var details: String?
  var categoryId: UUID
}

extension CreateReportDTO: Validatable {
  static func validations(_ validations: inout Validations) {
    validations.add("details", as: String.self, is: .count(1...10000), required: false)
    validations.add("categoryId", as: UUID.self)
  }
}
