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

      .field("name", .sql(unsafeRaw: "VARCHAR(50)"), .required)
      .field("address", .sql(unsafeRaw: "VARCHAR(255)"))
      .field("zip_code", .sql(unsafeRaw: "VARCHAR(6)"))
      .field("city", .sql(unsafeRaw: "VARCHAR(50)"))
      .field("country", .sql(unsafeRaw: "VARCHAR(50)"))
      .field("phone_number", .sql(unsafeRaw: "VARCHAR(16)"))
      .field("email", .sql(unsafeRaw: "VARCHAR(255)"))
      .field("website", .sql(unsafeRaw: "VARCHAR(255)"))
      .field("other_details", .sql(unsafeRaw: "TEXT"))
      .field("latitude", .sql(unsafeRaw: "DECIMAL(8,6)"), .required)
      .field("longitude", .sql(unsafeRaw: "DECIMAL(9,6)"), .required)
      .field("creation_date", .sql(unsafeRaw: "TIMESTAMP"), .required, .sql(unsafeRaw: "DEFAULT CURRENT_TIMESTAMP"))
      .field("last_update_date", .sql(unsafeRaw: "TIMESTAMP"), .required)

    if database is any MySQLDatabase {
      builder.field("location", .sql(unsafeRaw: "POINT"), .required)
    }

    try await builder.create()
  }

  func revert(on database: any Database) async throws {
    try await database.schema("places").delete()
  }
}
