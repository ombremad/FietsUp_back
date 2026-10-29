//
//  CreateForumCategories.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 24/09/2026.
//

import Fluent

struct CreateForumCategories: AsyncMigration {
  func prepare(on database: any Database) async throws {
    try await database.schema("forum_categories")
      .id()

      .field("name", .sql(unsafeRaw: "VARCHAR(50)"), .required)
      .field("details", .sql(unsafeRaw: "TEXT"))
      .field("last_activity_date", .sql(unsafeRaw: "TIMESTAMP"), .required, .sql(unsafeRaw: "DEFAULT CURRENT_TIMESTAMP"))

      .unique(on: "name")

      .create()
  }
  
  func revert(on database: any Database) async throws {
    try await database.schema("forum_categories").delete()
  }
}
