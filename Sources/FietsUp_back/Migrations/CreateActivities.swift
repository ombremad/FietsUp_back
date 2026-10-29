//
//  CreateActivities.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 24/09/2026.
//

import Fluent

struct CreateActivities: AsyncMigration {
  func prepare(on database: any Database) async throws {
    try await database.schema("activities")
      .id()

      .field("start_date", .sql(unsafeRaw: "TIMESTAMP"), .required)
      .field("end_date", .sql(unsafeRaw: "TIMESTAMP"), .required)
      .field("length", .sql(unsafeRaw: "SMALLINT"), .required)
      .field("distance", .sql(unsafeRaw: "INT"), .required)

      .field("id_user", .uuid, .required, .references("users", "id", onDelete: .cascade))

      .create()
  }

  func revert(on database: any Database) async throws {
    try await database.schema("activities").delete()
  }
}
