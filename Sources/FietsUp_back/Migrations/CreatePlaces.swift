//
//  CreatePlaces.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 02/10/2026.
//

import Fluent
import FluentMySQLDriver

struct CreatePlaces: AsyncMigration {
  func prepare(on database: any Database) async throws {
    let builder = database.schema("places")
      .id()

      .field("name", .string, .required)
      .field("address", .string)
      .field("zip_code", .string)
      .field("city", .string)
      .field("country", .string)
      .field("phone_number", .string)
      .field("email", .string)
      .field("website", .string)
      .field("other_details", .string)
      .field("latitude", .double, .required)
      .field("longitude", .double, .required)
      .field("creation_date", .datetime, .required)
      .field("last_update_date", .datetime, .required)

    if database is any MySQLDatabase {
      builder.field("location", .sql(unsafeRaw: "POINT"), .required)
    }

    try await builder.create()
  }

  func revert(on database: any Database) async throws {
    try await database.schema("places").delete()
  }
}
