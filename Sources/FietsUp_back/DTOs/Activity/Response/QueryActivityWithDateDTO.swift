//
//  QueryActivityWithDateDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 13/09/2026.
//

import Vapor

struct QueryActivityWithDateDTO: Content, PageValidatable {
  let start: Date?
  let end: Date?
  let page: Int?
  let per: Int?
}

extension QueryActivityWithDateDTO {
  static func validations(_ validations: inout Validations) {
    validatePagination(&validations)
    validations.add("start", as: Date.self, required: false)
    validations.add("end", as: Date.self, required: false)
  }
}
