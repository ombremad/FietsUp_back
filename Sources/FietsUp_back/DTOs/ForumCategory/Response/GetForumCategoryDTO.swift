//
//  GetForumCategoryDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 26/03/2026.
//

import Vapor

struct GetForumCategoryDTO: Content {
  var id: UUID
  var name: String
  var details: String?
  var posts: [GetForumPostWithCountsDTO]
}

extension GetForumCategoryDTO {
  init(from model: ForumCategory, commentCounts: [UUID: Int]) throws {
    guard let id = model.id else { throw Abort(.internalServerError) }
    
    self.init(
      id: id,
      name: model.name,
      details: model.details,
      posts: try model.forumPosts.map {
        try GetForumPostWithCountsDTO(from: $0, totalComments: commentCounts[$0.requireID()] ?? 0)
      }
    )
  }
}
