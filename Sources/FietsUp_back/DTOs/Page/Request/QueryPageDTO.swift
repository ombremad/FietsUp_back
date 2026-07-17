//
//  QueryPageDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 17/07/2026.
//

import Vapor

struct QueryPageDTO: Content {
  let page: Int?
  let per: Int?
}

extension QueryPageDTO: Validatable {
  static func validations(_ validations: inout Validations) {
    validations.add("page", as: Int.self, is: .range(1...), required: false)
    validations.add("per", as: Int.self, is: .range(1...), required: false)
  }
}
