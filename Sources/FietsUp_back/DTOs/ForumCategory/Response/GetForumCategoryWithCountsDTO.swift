//
//  GetForumCategoryDetailsDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 27/03/2026.
//

import Vapor
import Fluent

struct GetForumCategoryWithCountsDTO: Content {
  var id: UUID
  var name: String
  var details: String?
  var lastActivityDate: Date?
  var totalPosts: Int?
}

extension GetForumCategoryWithCountsDTO {
  init(from model: ForumCategoryWithCounts) throws {
    guard let id = model.id else { throw Abort(.internalServerError) }
    
    self.init(
      id: id,
      name: model.name,
      details: model.details,
      lastActivityDate: model.lastActivityDate,
      totalPosts: model.totalPosts
    )
  }
}
