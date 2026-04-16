//
//  CreateForumPostReportDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 16/04/2026.
//

import Vapor

struct CreateForumPostReportDTO: Content {
  var details: String
  var categoryID: UUID
}

extension CreateForumPostReportDTO: Validatable {
  static func validations(_ validations: inout Validations) {
    validations.add("details", as: String.self, is: .count(1...10000))
  }
}
