//
//  GetActivityDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 24/03/2026.
//

import Vapor

struct GetActivityDTO: Content {
  var id: UUID
  var startDate: Date
  var endDate: Date
  var length: Int
  var distance: Int
  var streakUpdated: Bool?
}

extension GetActivityDTO {
  init(from model: Activity, streakUpdated: Bool? = nil) throws {
    guard let id = model.id else { throw Abort(.internalServerError) }
    
    self.init(
      id: id,
      startDate: model.startDate,
      endDate: model.endDate,
      length: model.length,
      distance: model.distance,
      streakUpdated: streakUpdated
    )
  }
}
