//
//  InternationalPhoneNumberValidator.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 25/03/2026.
//

import Vapor

extension Validator where T == String {
  static var internationalPhoneNumber: Validator<String> {
    .pattern(#"^\+?[0-9]+$"#) &&
    .count(4...16)
  }
}
