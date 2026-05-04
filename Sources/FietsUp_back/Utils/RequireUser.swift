//
//  RequireUser.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 24/03/2026.
//

import Vapor
import Fluent

extension Request {
  func requireUser() async throws -> User {
    let payload = try self.auth.require(UserPayload.self)
    guard let user = try await User.find(payload.id, on: self.db)
    else {
      throw Abort(.notFound, reason: "User not found")
    }
    return user
  }
}

extension Request {
  func requireUserWithCycle() async throws -> User {
    let payload = try self.auth.require(UserPayload.self)
    guard let user = try await User.query(on: self.db)
      .filter(\.$id == payload.id)
      .withCycle()
      .first()
    else {
      throw Abort(.notFound, reason: "User not found")
    }
    return user
  }
}
