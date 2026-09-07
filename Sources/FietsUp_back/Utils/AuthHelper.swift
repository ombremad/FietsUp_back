//
//  AuthHelper.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 20/07/2026.
//

import Vapor
import JWT

enum AuthHelper {
  static func verifyUser(token: String, on request: Request) async throws -> User {
    let signer = JWTSigner.hs256(key: JWTConfig.shared.jwtSecret)
    let payload: UserPayload
    
    do {
      payload = try signer.verify(token, as: UserPayload.self)
    } catch {
      throw Abort(.unauthorized, reason: "Invalid token")
    }
    
    guard let user = try await User.find(payload.id, on: request.db) else {
      throw Abort(.unauthorized, reason: "User not found")
    }
    
    if let banEndDate = user.banEndDate, banEndDate >= .now {
      throw Abort(.unauthorized, reason: "User is banned until \(banEndDate.description)")
    }
    
    return user
  }
}
