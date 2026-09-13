//
//  GetPlaceCategoryDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 25/03/2026.
//

import Vapor

struct GetPlaceCategoryDTO: Content {
  var id: UUID
  var name: String
  var iconName: String
}

extension GetPlaceCategoryDTO {
  init(from model: PlaceCategory) throws {
    guard let id = model.id else { throw
      Abort(.internalServerError) }
    
    self.init(
      id: id,
      name: model.name,
      iconName: model.iconName
    )
  }
}
