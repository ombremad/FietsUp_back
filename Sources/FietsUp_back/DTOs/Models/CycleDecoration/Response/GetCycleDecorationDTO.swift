//
//  GetCycleDecorationDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 29/04/2026.
//

import Vapor

struct GetCycleDecorationDTO: Content {
  var id: UUID
  var name: String
  var fileLink: String
}

extension GetCycleDecorationDTO {
  init(from model: CycleDecoration) throws {
    guard let id = model.id else { throw
      Abort(.internalServerError) }
    
    self.init(
      id: id,
      name: model.name,
      fileLink: model.fileLink
    )
  }
}
