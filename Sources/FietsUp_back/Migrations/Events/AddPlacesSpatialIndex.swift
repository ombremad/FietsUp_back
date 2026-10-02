//
//  AddPlacesSpatialIndex.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 02/10/2026.
//

import Fluent
import SQLKit

struct AddPlacesSpatialIndex: AsyncMigration {
  func prepare(on database: any Database) async throws {
    guard let sql = database as? any SQLDatabase else { return }
    try await sql.raw("CREATE SPATIAL INDEX places_location_sidx ON places (location)").run()
  }

  func revert(on database: any Database) async throws {
    guard let sql = database as? any SQLDatabase else { return }
    try await sql.raw("DROP INDEX places_location_sidx ON places").run()
  }
}
