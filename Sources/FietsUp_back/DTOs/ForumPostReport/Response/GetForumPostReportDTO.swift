//
//  GetForumPostReportDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 16/04/2026.
//

import Vapor

struct GetForumPostReportDTO: Content {
  var id: UUID
  var details: String
  var processDetails: String?
  var creationDate: Date?
  var processDate: Date?
  var forumPost: GetForumPostShortDTO?
  var user: GetUserShortDTO
  var category: GetModerationCategoryDTO
}

extension GetForumPostReportDTO {
  init(from model: ForumPostReport) throws {
    guard let id = model.id else { throw Abort(.internalServerError) }
    
    self.init(
      id: id,
      details: model.details,
      processDetails: model.processDetails,
      creationDate: model.creationDate,
      processDate: model.processDate,
      forumPost: try model.forumPost.map { try GetForumPostShortDTO(from: $0) },
      user: try GetUserShortDTO(from: model.user),
      category: try GetModerationCategoryDTO(from: model.moderationCategory)
    )
  }
}
