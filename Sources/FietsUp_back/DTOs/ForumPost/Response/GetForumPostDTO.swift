//
//  GetForumPostDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 26/03/2026.
//

import Vapor

struct GetForumPostDTO: Content {
  var id: UUID
  var title: String
  var content: String
  var user: GetUserShortDTO
  var creationDate: Date?
  var comments: [GetForumCommentDTO]
}

extension GetForumPostDTO {
  init(from model: ForumPost) throws {
    guard let id = model.id else { throw Abort(.internalServerError) }
    
    self.init(
      id: id,
      title: model.title,
      content: model.content,
      user: try GetUserShortDTO(from: model.user),
      creationDate: model.creationDate,
      comments: try model.forumComments.map { try GetForumCommentDTO(from: $0) }
    )
  }
}
