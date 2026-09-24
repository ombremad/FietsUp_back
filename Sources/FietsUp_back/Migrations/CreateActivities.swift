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
    
      .field("start_date", .datetime, .required)
      .field("end_date", .datetime, .required)
      .field("length", .int, .required)
      .field("distance", .int, .required)
    
      .field("id_user", .uuid, .required, .references("users", "id"))

      .create()
  }
  
  func revert(on database: any Database) async throws {
    try await database.schema("activities").delete()
  }
}
