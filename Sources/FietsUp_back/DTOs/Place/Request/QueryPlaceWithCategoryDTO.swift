//
//  QueryPlaceWithCategoryDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 13/09/2026.
//

import Vapor

struct QueryPlaceWithCategoryDTO: Content, PageValidatable {
  let categoryID: UUID?
  let page: Int?
  let per: Int?
}

extension QueryPlaceWithCategoryDTO {
  static func validations(_ validations: inout Validations) {
    validatePagination(&validations)
    validations.add("categoryID", as: UUID.self, required: false)
  }
}
