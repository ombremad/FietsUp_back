//
//  JWTConfig.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 17/02/2026.
//

import Vapor
import JWT

struct JWTConfig {
    static let shared = JWTConfig()
    
    let jwtSecret = Environment.get("JWT_SECRET") ?? "mysecretkey"
    
    func sign(_ payload: UserPayload) throws -> String {
        let signer = JWTSigner.hs256(key: jwtSecret)
        return try signer.sign(payload)
    }
}
