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
  var daysSinceSignup: Int
  var totalElapsedDistance: Int
  var bio: String?
  var cycleColor: GetCycleColorDTO?
  var cycleType: GetCycleTypeDTO?
  var cycleDecoration: GetCycleDecorationDTO?
}

extension GetUserPublicDTO {
  init(from model: User) throws {
    guard let id = model.id else { throw Abort(.internalServerError) }
    
    let daysSinceSignup = Calendar.current.dateComponents([.day], from: model.creationDate!, to: Date()).day ?? 0
    
    self.init(
      id: id,
      nickname: model.nickname,
      streak: model.streak,
      daysSinceSignup: daysSinceSignup,
      totalElapsedDistance: model.totalElapsedDistance,
      bio: model.bio,
      cycleColor: try model.cycleColor.map { try GetCycleColorDTO(from: $0) },
      cycleType: try model.cycleType.map { try GetCycleTypeDTO(from: $0) },
      cycleDecoration: try model.cycleDecoration.map { try GetCycleDecorationDTO(from: $0) },
    )
  }
}
