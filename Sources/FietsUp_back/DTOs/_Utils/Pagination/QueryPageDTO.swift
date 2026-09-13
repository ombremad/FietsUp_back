//
//  QueryPageDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 17/07/2026.
//

import Vapor

struct QueryPageDTO: Content, PageValidatable {
  let page: Int?
  let per: Int?
}

extension QueryPageDTO {
  static func validations(_ validations: inout Validations) {
    validatePagination(&validations)
  }
}
