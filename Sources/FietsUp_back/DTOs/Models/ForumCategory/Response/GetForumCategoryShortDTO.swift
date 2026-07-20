//
//  GetForumCategoryShortDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 08/07/2026.
//

import Vapor

struct GetForumCategoryShortDTO: Content {
  var id: UUID
  var name: String
  var details: String?
}

extension GetForumCategoryShortDTO {
  init(from model: ForumCategory) throws {
    guard let id = model.id else { throw Abort(.internalServerError) }
    
    self.init(
      id: id,
      name: model.name,
      details: model.details
    )
  }
}
