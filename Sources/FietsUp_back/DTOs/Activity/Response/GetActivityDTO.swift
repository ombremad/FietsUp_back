//
//  GetActivityDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 24/03/2026.
//

import Vapor
import Fluent

struct GetActivityDTO: Content {
  var id: UUID
  var startDate: Date
  var endDate: Date
  var length: Int
  var distance: Int
}

extension GetActivityDTO {
  init(from model: Activity) throws {
    self.init(
      id: model.id!,
      startDate: model.startDate,
      endDate: model.endDate,
      length: model.length,
      distance: model.distance
    )
  }
}
