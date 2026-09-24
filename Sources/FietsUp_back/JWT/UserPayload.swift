//
//  UserPayload.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 17/02/2026.
//

import JWT
import Vapor

struct UserPayload: JWTPayload, Authenticatable {
  var id: UUID
  var expiration: Date

  func verify(using signer: JWTSigner) throws {
    if self.expiration < Date() {
      throw JWTError.invalidJWK
    }
  }

  init(id: UUID) {
    let expiryDays = 7
    let expiry = TimeInterval(3600 * 24 * expiryDays)
    
    self.id = id
    self.expiration = Date().addingTimeInterval(expiry)
  }
}
