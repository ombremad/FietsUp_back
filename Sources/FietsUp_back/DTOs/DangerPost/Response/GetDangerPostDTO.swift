//
//  GetDangerPostDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 26/03/2026.
//

import Vapor

struct GetDangerPostDTO: Content {
  var id: UUID
  var title: String
  var content: String
  var latitude: Double
  var longitude: Double
  var user: GetUserShortDTO
  var creationDate: Date?
  var comments: [GetDangerCommentDTO]
}

extension GetDangerPostDTO {
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
      comments: try model.dangerComments.map { try GetDangerCommentDTO(from: $0) }
    )
  }
}
