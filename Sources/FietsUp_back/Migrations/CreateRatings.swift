//
//  CreateRatings.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 02/10/2026.
//

import Fluent

struct CreateRatings: AsyncMigration {
  func prepare(on database: any Database) async throws {
    try await database.schema("ratings")
      .id()
    
      .field("note", .int, .required)

      .field("id_user", .uuid, .required, .references("users", "id"))
      .field("id_place", .uuid, .required, .references("places", "id"))

      .create()
  }
  
  func revert(on database: any Database) async throws {
    try await database.schema("ratings").delete()
  }
}
