//
//  GetForumCommentReportDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 17/04/2026.
//

import Vapor

struct GetForumCommentReportDTO: Content {
  var id: UUID
  var details: String?
  var processDetails: String?
  var creationDate: Date?
  var processDate: Date?
  var forumComment: GetForumCommentShortDTO?
  var user: GetUserShortDTO
  var category: GetModerationCategoryDTO
}

extension GetForumCommentReportDTO {
  init(from model: ForumCommentReport) throws {
    guard let id = model.id else { throw Abort(.internalServerError) }
    
    self.init(
      id: id,
      details: model.details,
      processDetails: model.processDetails,
      creationDate: model.creationDate,
      processDate: model.processDate,
      forumComment: try model.forumComment.map { try GetForumCommentShortDTO(from: $0) },
      user: try GetUserShortDTO(from: model.user),
      category: try GetModerationCategoryDTO(from: model.moderationCategory)
    )
  }
}
