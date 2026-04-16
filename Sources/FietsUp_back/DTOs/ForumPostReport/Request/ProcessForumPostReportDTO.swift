//
//  ProcessForumPostReportDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 16/04/2026.
//

import Vapor

struct ProcessForumPostReportDTO: Content {
  var details: String
}

extension ProcessForumPostReportDTO: Validatable {
  static func validations(_ validations: inout Validations) {
    validations.add("details", as: String.self, is: .count(1...10000))
  }
}
