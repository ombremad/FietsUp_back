//
//  ProcessDangerCommentReportDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 17/04/2026.
//

import Vapor

struct ProcessDangerCommentReportDTO: Content {
  var details: String
}

extension ProcessDangerCommentReportDTO: Validatable {
  static func validations(_ validations: inout Validations) {
    validations.add("details", as: String.self, is: .count(1...10000))
  }
}

