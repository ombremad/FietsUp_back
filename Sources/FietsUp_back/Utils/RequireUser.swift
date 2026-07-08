//
//  RequireUser.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 24/03/2026.
//

import Vapor
import Fluent

extension Request {
  func requireUser() throws -> User {
    try self.auth.require(User.self)
  }
}

extension Request {
  func requireUserWithCycle() async throws -> User {
    let currentUser = try self.auth.require(User.self)
    let currentUserID = try currentUser.requireID()
    
    guard let user = try await User.query(on: self.db)
      .filter(\.$id == currentUserID)
      .withCycle()
      .first()
    else {
      throw Abort(.notFound, reason: "User not found")
    }
    return user
  }
}
