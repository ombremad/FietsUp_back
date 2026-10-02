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

      .field("note", .uint8, .required)

      .field("id_user", .uuid, .required, .references("users", "id", onDelete: .cascade))
      .field("id_place", .uuid, .required, .references("places", "id", onDelete: .cascade))

      .unique(on: "id_user", "id_place")

      .create()
  }

  func revert(on database: any Database) async throws {
    try await database.schema("ratings").delete()
  }
}
