//
//  GetForumPostWithCountsDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 31/03/2026.
//

import Vapor

struct GetForumPostWithCountsDTO: Content {
  var id: UUID
  var title: String
  var content: String
  var user: GetUserShortDTO
  var creationDate: Date?
  var totalComments: Int
}

extension GetForumPostWithCountsDTO {
  init(from model: ForumPost, totalComments: Int) throws {
    guard let id = model.id else { throw Abort(.internalServerError) }
    
    self.init(
      id: id,
      title: model.title,
      content: model.content,
      user: try GetUserShortDTO(from: model.user),
      creationDate: model.creationDate,
      totalComments: totalComments
    )
  }
}
