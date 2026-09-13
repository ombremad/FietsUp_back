//
//  GetCycleColorDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 29/04/2026.
//

import Vapor

struct GetCycleColorDTO: Content {
  var id: UUID
  var name: String
  var color: String
}

extension GetCycleColorDTO {
  init(from model: CycleColor) throws {
    guard let id = model.id else { throw
      Abort(.internalServerError) }
    
    self.init(
      id: id,
      name: model.name,
      color: model.color
    )
  }
}
