//
//  GetUserShortDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 17/04/2026.
//

import Vapor

struct GetUserShortDTO: Content {
  var id: UUID
  var firstName: String
  var lastName: String
  var nickname: String
  var email: String
  var creationDate: Date?
}

extension GetUserShortDTO {
  init(from model: User) throws {
    guard let id = model.id else { throw Abort(.internalServerError) }
    
    self.init(
      id: id,
      firstName: model.firstName,
      lastName: model.lastName,
      nickname: model.nickname,
      email: model.email,
      creationDate: model.creationDate
    )
  }
}
