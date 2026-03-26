//
//  GetDangerCommentDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 26/03/2026.
//

import Vapor

struct GetDangerCommentDTO: Content {
  var id: UUID
  var content: String
  var user: GetUserShortDTO
  var creationDate: Date?
}

extension GetDangerCommentDTO {
  init(from model: DangerComment) throws {
    guard let id = model.id else {
      throw Abort(.internalServerError)
    }
    
    self.init(
      id: id,
      content: model.content,
      user: try GetUserShortDTO(from: model.user),
      creationDate: model.creationDate
    )
  }
}
