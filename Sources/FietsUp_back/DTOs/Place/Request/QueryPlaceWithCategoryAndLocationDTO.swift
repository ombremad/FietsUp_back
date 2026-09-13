//
//  QueryPlaceWithCategoryAndLocationDTO.swift.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 13/09/2026.
//

import Vapor

struct QueryPlaceWithCategoryAndLocationDTO: Content {
  let latitude: Double
  let longitude: Double
  let categoryID: UUID?
}

extension QueryPlaceWithCategoryAndLocationDTO: Validatable {
  static func validations(_ validations: inout Validations) {
    validations.add("latitude", as: Double.self, is: .range(-90.0...90.0))
    validations.add("longitude", as: Double.self, is: .range(-180.0...180.0))
    validations.add("categoryID", as: UUID.self, required: false)
  }
}
