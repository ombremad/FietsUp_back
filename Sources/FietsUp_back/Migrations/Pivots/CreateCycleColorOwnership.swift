//
//  CreateCycleColorOwnership.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 02/10/2026.
//

import Fluent

struct CreateCycleColorOwnership: AsyncMigration {
  func prepare(on database: any Database) async throws {
    try await database.schema("cycle_color_ownership")
      .id()

      .field("id_user", .uuid, .required, .references("users", "id", onDelete: .cascade))
      .field("id_cycle_color", .uuid, .required, .references("cycle_colors", "id"))

      .unique(on: "id_user", "id_cycle_color")

      .create()
  }

  func revert(on database: any Database) async throws {
    try await database.schema("cycle_color_ownership").delete()
  }
}
