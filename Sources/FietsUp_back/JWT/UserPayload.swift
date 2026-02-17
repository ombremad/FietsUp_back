//
//  UserPayload.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 17/02/2026.
//

import Vapor
import JWT

struct UserPayload: JWTPayload, Authenticatable {
    var id: UUID
    var expiration: Date
    
    func verify(using signer: JWTSigner) throws {
        if self.expiration < Date() {
            throw JWTError.invalidJWK // Throw an error if the token has expired
        }
    }
    
    init(id: UUID) {
        self.id = id
        self.expiration = Date().addingTimeInterval(3600 * 24 * 30) // Expire in 30 days
    }
}
