//
//  DatabaseErrorMiddleware.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 29/10/2026.
//

import FluentMySQLDriver
import Vapor

struct DatabaseErrorMiddleware: AsyncMiddleware {
  func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
    do {
      return try await next.respond(to: request)
    } catch MySQLError.duplicateEntry {
      throw Abort(.conflict, reason: "A record with this value already exists")
    }
  }
}
