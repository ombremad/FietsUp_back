//
//  GetForumPostShortDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 16/04/2026.
//

import Vapor

struct GetForumPostShortDTO: Content {
  var id: UUID
  var title: String
  var content: String
  var user: GetUserShortDTO
  var creationDate: Date?
}

extension GetForumPostShortDTO {
  init(from model: ForumPost) throws {
    guard let id = model.id else { throw Abort(.internalServerError) }
    
    self.init(
      id: id,
      title: model.title,
      content: model.content,
      user: try GetUserShortDTO(from: model.user),
      creationDate: model.creationDate
    )
  }
}
