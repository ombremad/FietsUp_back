//
//  CreateForumCategoryDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 26/03/2026.
//

import Vapor

struct CreateForumCategoryDTO: Content {
  var name: String
  var details: String?
}

extension CreateForumCategoryDTO: Validatable {
  static func validations(_ validations: inout Validations) {
    validations.add("name", as: String.self, is: .count(1...50))
    validations.add("details", as: String.self, is: .count(1...10000), required: false)
  }
}
