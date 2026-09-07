//
//  GetModerationCategoryDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 26/03/2026.
//

import Vapor

struct GetModerationCategoryDTO: Content {
  var id: UUID
  var name: String
}

extension GetModerationCategoryDTO {
  init(from model: ModerationCategory) throws {
    guard let id = model.id else { throw
      Abort(.internalServerError) }
    
    self.init(
      id: id,
      name: model.name
    )
  }
}
