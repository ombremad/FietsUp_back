//
//  CreateDangerPostReportDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 17/04/2026.
//

import Vapor

struct CreateDangerPostReportDTO: Content {
  var details: String?
  var categoryID: UUID
}
