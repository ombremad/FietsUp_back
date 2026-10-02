//
//  CreatePlaceCategorization.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 02/10/2026.
//

import Fluent

struct CreatePlaceCategorization: AsyncMigration {
  func prepare(on database: any Database) async throws {
    try await database.schema("place_categorization")
      .id()

      .field("id_place", .uuid, .required, .references("places", "id", onDelete: .cascade))
      .field("id_place_category", .uuid, .required, .references("place_categories", "id", onDelete: .cascade))

      .unique(on: "id_place", "id_place_category")

      .create()
  }

  func revert(on database: any Database) async throws {
    try await database.schema("place_categorization").delete()
  }
}
