//
//  CreatePlaceCategories.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 02/10/2026.
//

import Fluent

struct CreatePlaceCategories: AsyncMigration {
  func prepare(on database: any Database) async throws {
    try await database.schema("place_categories")
      .id()

      .field("name", .sql(unsafeRaw: "VARCHAR(50)"), .required)
      .field("icon_name", .sql(unsafeRaw: "VARCHAR(100)"), .required)

      .unique(on: "name")

      .create()
  }
  
  func revert(on database: any Database) async throws {
    try await database.schema("place_categories").delete()
  }
}
