//
//  PasswordValidator.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 02/02/2026.
//

import Vapor

import Vapor

extension Validator where T == String {
  static var securePassword: Validator<T> {
    .init { input in
      var errors: [String] = []
      
      if input.isEmpty {
        errors.append("cannot be empty")
      }
      if input.count < 8 {
        errors.append("must be at least 8 characters")
      }
      if input.range(of: ".*[A-Z]+.*", options: .regularExpression) == nil {
        errors.append("must contain at least 1 uppercase letter")
      }
      if input.range(of: ".*[a-z]+.*", options: .regularExpression) == nil {
        errors.append("must contain at least 1 lowercase letter")
      }
      if input.range(of: ".*[0-9]+.*", options: .regularExpression) == nil {
        errors.append("must contain at least 1 number")
      }
      if input.range(of: ".*[!@#$%^&*()_+\\-=\\[\\]{};':\"\\\\|,.<>\\/?]+.*", options: .regularExpression) == nil {
        errors.append("must contain at least 1 special character")
      }
      
      return ValidatorResults.Password(errors: errors)
    }
  }
}

extension ValidatorResults {
  struct Password: ValidatorResult {
    let errors: [String]
    
    var isFailure: Bool { !errors.isEmpty }
    var successDescription: String? { "is a valid password" }
    var failureDescription: String? {
      errors.isEmpty ? nil : errors.joined(separator: ", ")
    }
  }
}
