//
//  CreateForumPostReportDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 16/04/2026.
//

import Vapor

struct CreateForumPostReportDTO: Content {
  var details: String?
  var categoryID: UUID
}
