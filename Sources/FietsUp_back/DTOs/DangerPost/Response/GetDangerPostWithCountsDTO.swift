//
//  GetDangerPostWithCountsDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 13/04/2026.
//

import Vapor

struct GetDangerPostWithCountsDTO: Content {
  var id: UUID
  var title: String
  var content: String
  var latitude: Double
  var longitude: Double
  var user: GetUserPublicDTO
  var creationDate: Date?
  var dangerCategory: GetDangerCategoryDTO
  var totalComments: Int
}

extension GetDangerPostWithCountsDTO {
  init(from model: DangerPost, totalComments: Int) throws {
    guard let id = model.id else { throw Abort(.internalServerError) }
    
    self.init(
      id: id,
      title: model.title,
      content: model.content,
      latitude: model.latitude,
      longitude: model.longitude,
      user: try GetUserPublicDTO(from: model.user),
      creationDate: model.creationDate,
      dangerCategory: try GetDangerCategoryDTO(from: model.dangerCategory),
      totalComments: totalComments
    )
  }
}
