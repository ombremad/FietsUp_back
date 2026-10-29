//
//  ConfigureTimeZone.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 29/10/2026.
//

import Fluent
import FluentMySQLDriver

struct ConfigureTimeZone: AsyncMigration {
  func prepare(on database: any Database) async throws {
    guard let mysql = database as? any MySQLDatabase else { return }
    try await mysql.execute("SET GLOBAL time_zone = '+00:00'")
  }

  func revert(on database: any Database) async throws {
    guard let mysql = database as? any MySQLDatabase else { return }
    try await mysql.execute("SET GLOBAL time_zone = 'SYSTEM'")
  }
}
