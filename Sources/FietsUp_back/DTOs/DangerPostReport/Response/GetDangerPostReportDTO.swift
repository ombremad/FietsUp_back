//
//  GetDangerPostReportDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 17/04/2026.
//

import Vapor

struct GetDangerPostReportDTO: Content {
  var id: UUID
  var details: String?
  var processDetails: String?
  var creationDate: Date?
  var processDate: Date?
  var dangerPost: GetDangerPostShortDTO?
  var user: GetUserPublicDTO
  var category: GetModerationCategoryDTO
}

extension GetDangerPostReportDTO {
  init(from model: DangerPostReport) throws {
    guard let id = model.id else { throw Abort(.internalServerError) }
    
    self.init(
      id: id,
      details: model.details,
      processDetails: model.processDetails,
      creationDate: model.creationDate,
      processDate: model.processDate,
      dangerPost: try model.dangerPost.map { try GetDangerPostShortDTO(from: $0) },
      user: try GetUserPublicDTO(from: model.user),
      category: try GetModerationCategoryDTO(from: model.moderationCategory)
    )
  }
}
