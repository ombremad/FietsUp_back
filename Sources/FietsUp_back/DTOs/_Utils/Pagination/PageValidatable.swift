//
//  PageValidatable.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 13/09/2026.
//

import Vapor

protocol PageValidatable: Validatable {
  var page: Int? { get }
  var per: Int? { get }
}

extension PageValidatable {
  static func validatePagination(_ validations: inout Validations) {
    validations.add("page", as: Int.self, is: .range(1...), required: false)
    validations.add("per", as: Int.self, is: .range(1...20), required: false)
  }
}
