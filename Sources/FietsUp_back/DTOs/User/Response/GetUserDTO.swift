//
//  GetUserDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 02/02/2026.
//

import Vapor

struct GetUserDTO: Content {
  var id: UUID
  var firstName: String
  var lastName: String
  var nickname: String
  var email: String
  var bio: String?
  var streak: Int
  var daysSinceSignup: Int
  var totalElapsedDistance: Int
}

extension GetUserDTO {
  init(from model: User) throws {
    guard let id = model.id else { throw Abort(.internalServerError) }
    
    let daysSinceSignup = Calendar.current.dateComponents([.day], from: model.creationDate!, to: Date()).day ?? 0

    self.init(
      id: id,
      firstName: model.firstName,
      lastName: model.lastName,
      nickname: model.nickname,
      email: model.email,
      bio: model.bio,
      streak: model.streak,
      daysSinceSignup: daysSinceSignup,
      totalElapsedDistance: model.totalElapsedDistance
    )
  }
}
