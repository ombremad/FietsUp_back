//
//  ProcessDangerPostReportDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 17/04/2026.
//

import Vapor

struct ProcessDangerPostReportDTO: Content {
  var details: String
}

extension ProcessDangerPostReportDTO: Validatable {
  static func validations(_ validations: inout Validations) {
    validations.add("details", as: String.self, is: .count(1...10000))
  }
}
