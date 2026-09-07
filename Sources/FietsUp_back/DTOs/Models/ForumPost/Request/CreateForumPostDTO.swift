//
//  CreateForumPostDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 26/03/2026.
//

import Vapor

struct CreateForumPostDTO: Content {
  var title: String
  var content: String
}

extension CreateForumPostDTO: Validatable {
  static func validations(_ validations: inout Validations) {
    validations.add("title", as: String.self, is: .count(1...100))
    validations.add("content", as: String.self, is: .count(1...20000))
  }
}
