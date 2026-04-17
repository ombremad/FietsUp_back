//
//  GetDangerCommentShortDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 17/04/2026.
//

import Vapor
import Fluent

struct GetDangerCommentShortDTO: Content {
  var id: UUID
  var content: String
  var user: GetUserShortDTO
  var creationDate: Date?
}

extension GetDangerCommentShortDTO {
  init(from model: DangerComment) throws {
    guard let id = model.id else { throw Abort(.internalServerError) }
    
    self.init(
      id: id,
      content: model.content,
      user: try GetUserShortDTO(from: model.user),
      creationDate: model.creationDate
    )
  }
}
