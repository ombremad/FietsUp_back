//
//  GetForumCommentShortDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 17/04/2026.
//

import Vapor
import Fluent

struct GetForumCommentShortDTO: Content {
  var id: UUID
  var content: String
  var user: GetUserPublicDTO
  var creationDate: Date?
}

extension GetForumCommentShortDTO {
  init(from model: ForumComment) throws {
    guard let id = model.id else { throw Abort(.internalServerError) }
    
    self.init(
      id: id,
      content: model.content,
      user: try GetUserPublicDTO(from: model.user),
      creationDate: model.creationDate
    )
  }
}
