//
//  GetUserSummaryDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 26/03/2026.
//

import Vapor

struct GetUserPublicDTO: Content {
  var id: UUID
  var nickname: String
  var streak: Int
}

extension GetUserPublicDTO {
  init(from model: User) throws {
    guard let id = model.id else { throw Abort(.internalServerError) }
    
    self.init(
      id: id,
      nickname: model.nickname,
      streak: model.streak,
    )
  }
}
