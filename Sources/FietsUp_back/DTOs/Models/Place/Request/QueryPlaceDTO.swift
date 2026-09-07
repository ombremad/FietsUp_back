//
//  QueryPlaceDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 03/06/2026.
//

import Vapor

struct QueryPlaceDTO: Content {
  let latitude: Double
  let longitude: Double
}

extension QueryPlaceDTO: Validatable {
  static func validations(_ validations: inout Validations) {
    validations.add("latitude", as: Double.self, is: .range(-90.0...90.0))
    validations.add("longitude", as: Double.self, is: .range(-180.0...180.0))
  }
}
