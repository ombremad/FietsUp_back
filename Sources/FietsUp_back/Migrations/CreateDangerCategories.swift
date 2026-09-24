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
    
      .field("name", .string, .required)
      .field("icon_name", .string, .required)
      .field("last_activity_date", .datetime, .required)
    
      .unique(on: "name")

      .create()
  }
  
  func revert(on database: any Database) async throws {
    try await database.schema("danger_categories").delete()
  }
}
