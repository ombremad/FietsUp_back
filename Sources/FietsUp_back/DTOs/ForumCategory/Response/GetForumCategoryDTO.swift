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
}

extension GetForumCategoryDTO {
  init(from model: ForumCategory) throws {
    guard let id = model.id else { throw
      Abort(.internalServerError) }
    
    self.init(
      id: id,
      name: model.name,
      details: model.details
    )
  }
}
