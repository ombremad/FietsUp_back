//
//  MySQLExecute.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 29/10/2026.
//

import FluentMySQLDriver
import NIOCore

extension MySQLDatabase {
  /// Runs SQL over the text protocol, for statements MySQL refuses as prepared statements
  /// (CREATE/DROP TRIGGER, PROCEDURE, EVENT)
  func execute(_ sql: String) async throws {
    _ = try await self.simpleQuery(sql).get()
  }
}
