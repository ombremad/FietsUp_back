//
//  GetDangerPostShortDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 17/04/2026.
//

import Vapor
import Fluent

struct GetDangerPostShortDTO: Content {
  var id: UUID
  var title: String
  var content: String
  var latitude: Double
  var longitude: Double
  var user: GetUserShortDTO
  var creationDate: Date?
  var dangerCategory: GetDangerCategoryDTO
}

extension GetDangerPostShortDTO {
  init(from model: DangerPost) throws {
    guard let id = model.id else { throw Abort(.internalServerError) }
    
    self.init(
      id: id,
      title: model.title,
      content: model.content,
      latitude: model.latitude,
      longitude: model.longitude,
      user: try GetUserShortDTO(from: model.user),
      creationDate: model.creationDate,
      dangerCategory: try GetDangerCategoryDTO(from: model.dangerCategory)
    )
  }
}
