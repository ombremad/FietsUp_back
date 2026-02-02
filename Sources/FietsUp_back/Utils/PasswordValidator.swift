//
//  PasswordValidator.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 02/02/2026.
//

import Vapor

extension Validator where T == String {
    static var securePassword: Validator<T> {
        .init { input in
            guard !input.isEmpty else {
                return ValidatorResults.Password(isFailure: true, reason: "cannot be empty")
            }
            
            guard input.count >= 8 else {
                return ValidatorResults.Password(isFailure: true, reason: "must be at least 8 characters")
            }
            
            let uppercasePattern = ".*[A-Z]+.*"
            guard input.range(of: uppercasePattern, options: .regularExpression) != nil else {
                return ValidatorResults.Password(isFailure: true, reason: "must contain at least 1 uppercase letter")
            }
            
            let lowercasePattern = ".*[a-z]+.*"
            guard input.range(of: lowercasePattern, options: .regularExpression) != nil else {
                return ValidatorResults.Password(isFailure: true, reason: "must contain at least 1 lowercase letter")
            }
            
            let digitPattern = ".*[0-9]+.*"
            guard input.range(of: digitPattern, options: .regularExpression) != nil else {
                return ValidatorResults.Password(isFailure: true, reason: "must contain at least 1 number")
            }
            
            let specialPattern = ".*[!@#$%^&*()_+\\-=\\[\\]{};':\"\\\\|,.<>\\/?]+.*"
            guard input.range(of: specialPattern, options: .regularExpression) != nil else {
                return ValidatorResults.Password(isFailure: true, reason: "must contain at least 1 special character")
            }
            
            return ValidatorResults.Password(isFailure: false)
        }
    }
}

extension ValidatorResults {
    struct Password: ValidatorResult {
        let isFailure: Bool
        var successDescription: String? = "is a valid password"
        var failureDescription: String?
        
        init(isFailure: Bool, reason: String? = nil) {
            self.isFailure = isFailure
            self.failureDescription = reason
        }
    }
}
