//
//  CreateDangerPostDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 26/03/2026.
//

import Vapor

struct CreateDangerPostDTO: Content {
  var title: String
  var content: String
  var latitude: Double
  var longitude: Double
}

extension CreateDangerPostDTO: Validatable {
  static func validations(_ validations: inout Validations) {
    validations.add("title", as: String.self, is: .count(1...100))
    validations.add("content", as: String.self, is: .count(1...20000))
    validations.add("latitude", as: Double.self, is: .range(-90.0...90.0))
    validations.add("longitude", as: Double.self, is: .range(-180.0...180.0))
  }
}
