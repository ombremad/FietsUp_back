//
//  CreateModerationCategories.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 02/10/2026.
//

import Fluent

struct CreateModerationCategories: AsyncMigration {
  func prepare(on database: any Database) async throws {
    try await database.schema("moderation_categories")
      .id()

      .field("name", .string, .required)

      .unique(on: "name")

      .create()
  }
  
  func revert(on database: any Database) async throws {
    try await database.schema("moderation_categories").delete()
  }
}
