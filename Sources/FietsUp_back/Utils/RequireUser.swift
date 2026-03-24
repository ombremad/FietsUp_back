//
//  RequireUser.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 24/03/2026.
//

import Vapor

extension Request {
  func requireUser() async throws -> User {
    let payload = try self.auth.require(UserPayload.self)
    guard let user = try await User.find(payload.id, on: self.db) else {
      throw Abort(.notFound, reason: "User not found")
    }
    return user
  }
}
