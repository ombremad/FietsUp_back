//
//  GetDangerCategoryDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 26/03/2026.
//

import Vapor


struct GetDangerCategoryDTO: Content {
  var id: UUID
  var name: String
  var iconName: String
}

extension GetDangerCategoryDTO {
  init(from model: DangerCategory) throws {
    guard let id = model.id else { throw
      Abort(.internalServerError) }

    self.init(
      id: id,
      name: model.name,
      iconName: model.iconName
    )
  }
}
