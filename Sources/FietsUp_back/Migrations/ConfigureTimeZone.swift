//
//  ConfigureTimeZone.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 29/10/2026.
//

import Fluent

// No-op, kept so the migration history stays identical on databases that already ran it.
// The database server must run in UTC (`default-time-zone = '+00:00'`): `SET GLOBAL time_zone`
// only applied to connections opened afterwards, and reverting it changed the whole server.
// `TimeZoneCheck` logs an error at boot when the server isn't in UTC.
struct ConfigureTimeZone: AsyncMigration {
  func prepare(on database: any Database) async throws {}

  func revert(on database: any Database) async throws {}
}
