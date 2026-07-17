//
//  GetForumCategoryDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 26/03/2026.
//

import Vapor
import Fluent

struct GetForumCategoryWithPostsDTO: Content {
  var id: UUID
  var name: String
  var details: String?
  var posts: Page<GetForumPostWithCountsDTO>
}

extension GetForumCategoryWithPostsDTO {
  init(from model: ForumCategory, posts: Page<ForumPost>, commentCounts: [UUID: Int]) throws {
    guard let id = model.id else { throw Abort(.internalServerError) }
    
    self.init(
      id: id,
      name: model.name,
      details: model.details,
      posts: try posts.map {
        try GetForumPostWithCountsDTO(from: $0, totalComments: commentCounts[$0.requireID()] ?? 0)
      }
    )
  }
}
