//
//  PatchForumCommentDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 26/03/2026.
//

import Vapor

struct PatchForumCommentDTO: Content {
  var content: String?
}

extension PatchForumCommentDTO: Validatable {
  static func validations(_ validations: inout Validations) {
    validations.add("content", as: String.self, is: .count(1...20000), required: false)
  }
}
