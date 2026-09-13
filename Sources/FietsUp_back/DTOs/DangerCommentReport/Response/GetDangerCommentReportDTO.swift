//
//  GetDangerCommentReportDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 17/04/2026.
//

import Vapor

struct GetDangerCommentReportDTO: Content {
  var id: UUID
  var details: String?
  var processDetails: String?
  var creationDate: Date?
  var processDate: Date?
  var dangerComment: GetDangerCommentShortDTO?
  var user: GetUserPublicDTO
  var category: GetModerationCategoryDTO
}

extension GetDangerCommentReportDTO {
  init(from model: DangerCommentReport) throws {
    guard let id = model.id else { throw Abort(.internalServerError) }
    
    self.init(
      id: id,
      details: model.details,
      processDetails: model.processDetails,
      creationDate: model.creationDate,
      processDate: model.processDate,
      dangerComment: try model.dangerComment.map { try GetDangerCommentShortDTO(from: $0) },
      user: try GetUserPublicDTO(from: model.user),
      category: try GetModerationCategoryDTO(from: model.moderationCategory)
    )
  }
}
