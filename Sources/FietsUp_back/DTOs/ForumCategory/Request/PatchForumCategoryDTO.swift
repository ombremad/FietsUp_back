//
//  PatchForumCategoryDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 26/03/2026.
//

import Vapor

struct PatchForumCategoryDTO: Content {
  var name: String?
  var details: String??
}

// Make ?? variables nullable in the patch
extension PatchForumCategoryDTO {
  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    name = try container.decodeIfPresent(String.self, forKey: .name)
    details = try container.decodeNullablePatchVariable(String.self, forKey: .details)
  }
}

extension PatchForumCategoryDTO: Validatable {
  static func validations(_ validations: inout Validations) {
    validations.add("name", as: String.self, is: .count(1...50), required: false)
    validations.add("details", as: String.self, is: .count(1...10000), required: false)
  }
}
