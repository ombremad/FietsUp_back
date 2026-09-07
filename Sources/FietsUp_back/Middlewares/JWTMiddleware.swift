//
//  JWTMiddleware.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 17/02/2026.
//

import Vapor
import JWT

final class JWTMiddleware: AsyncMiddleware {
  func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
    guard let token = request.headers["Authorization"].first?.split(separator: " ").last else {
      throw Abort(.unauthorized, reason: "Missing token")
    }
    
    let user = try await AuthHelper.verifyUser(token: String(token), on: request)
    request.auth.login(user)
    return try await next.respond(to: request)
  }
}
