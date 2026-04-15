//
//  GetFormCommentDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 26/03/2026.
//

import Vapor

struct GetForumCommentDTO: Content {
  var id: UUID
  var content: String
  var user: GetUserShortDTO
  var creationDate: Date?
  var likeCount: Int
  var likedByUser: Bool
  var favedByUser: Bool
}

extension GetForumCommentDTO {
  init(from model: ForumComment, likeCount: Int, likedByUser: Bool, favedByUser: Bool) throws {
    guard let id = model.id else {
      throw Abort(.internalServerError)
    }
    
    self.init(
      id: id,
      content: model.content,
      user: try GetUserShortDTO(from: model.user),
      creationDate: model.creationDate,
      likeCount: likeCount,
      likedByUser: likedByUser,
      favedByUser: favedByUser
    )
  }
}
