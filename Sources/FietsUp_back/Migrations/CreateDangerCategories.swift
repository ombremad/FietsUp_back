//
//  CreateDangerCategories.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 24/09/2026.
//

import Fluent

struct CreateDangerCategories: AsyncMigration {
  func prepare(on database: any Database) async throws {
    try await database.schema("danger_categories")
      .id()

      .field("name", .sql(unsafeRaw: "VARCHAR(50)"), .required)
      .field("icon_name", .sql(unsafeRaw: "VARCHAR(100)"), .required)
      .field("last_activity_date", .sql(unsafeRaw: "TIMESTAMP"), .required, .sql(unsafeRaw: "DEFAULT CURRENT_TIMESTAMP"))

      .unique(on: "name")

      .create()
  }
  
  func revert(on database: any Database) async throws {
    try await database.schema("danger_categories").delete()
  }
}
