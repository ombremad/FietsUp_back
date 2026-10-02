//
//  CreateCycleDecorationOwnership.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 02/10/2026.
//

import Fluent

struct CreateCycleDecorationOwnership: AsyncMigration {
  func prepare(on database: any Database) async throws {
    try await database.schema("cycle_decoration_ownership")
      .id()

      .field("id_user", .uuid, .required, .references("users", "id", onDelete: .cascade))
      .field("id_cycle_decoration", .uuid, .required, .references("cycle_decorations", "id"))

      .unique(on: "id_user", "id_cycle_decoration")

      .create()
  }

  func revert(on database: any Database) async throws {
    try await database.schema("cycle_decoration_ownership").delete()
  }
}
