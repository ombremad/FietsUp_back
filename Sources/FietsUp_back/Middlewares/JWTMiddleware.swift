//
//  JWTMiddleware.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 17/02/2026.
//

import JWT
import Vapor

final class JWTMiddleware: AsyncMiddleware {
  func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
    guard let token = request.headers["Authorization"].first?.split(separator: " ").last else {
      throw Abort(.unauthorized, reason: "Missing token")
    }
    
    let signer = JWTSigner.hs256(key: JWTConfig.shared.jwtSecret)
    let payload: UserPayload
    
    do {
      payload = try signer.verify(String(token), as: UserPayload.self)
    } catch {
      throw Abort(.unauthorized, reason: "Invalid token")
    }
    
    guard let user = try await User.find(payload.id, on: request.db) else {
      throw Abort(.unauthorized, reason: "User not found")
    }
    
    if let banEndDate = user.banEndDate, banEndDate >= .now {
      throw Abort(.unauthorized, reason: "User is banned until \(banEndDate.description)")
    }
    
    request.auth.login(user)
    return try await next.respond(to: request)
  }
}
