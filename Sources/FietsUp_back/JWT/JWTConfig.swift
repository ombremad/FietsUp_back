//
//  JWTConfig.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 17/02/2026.
//

import Vapor

struct JWTConfig {
    static let shared = JWTConfig()
    
    // Get JWT secret key from schemes if available
    let jwtSecret = Environment.get("JWT_SECRET") ?? "mysecretkey"
}
