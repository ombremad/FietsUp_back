//
//  PatchForumPostDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 26/03/2026.
//

import Vapor

struct PatchForumPostDTO: Content {
  var title: String?
  var content: String?
}

extension PatchForumPostDTO: Validatable {
  static func validations(_ validations: inout Validations) {
    validations.add("title", as: String.self, is: .count(1...100), required: false)
    validations.add("content", as: String.self, is: .count(1...20000), required: false)
  }
}
