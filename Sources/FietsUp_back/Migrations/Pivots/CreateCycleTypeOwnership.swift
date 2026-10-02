//
//  CreateCycleTypeOwnership.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 02/10/2026.
//

import Fluent

struct CreateCycleTypeOwnership: AsyncMigration {
  func prepare(on database: any Database) async throws {
    try await database.schema("cycle_type_ownership")
      .id()

      .field("id_user", .uuid, .required, .references("users", "id", onDelete: .cascade))
      .field("id_cycle_type", .uuid, .required, .references("cycle_types", "id"))

      .unique(on: "id_user", "id_cycle_type")

      .create()
  }

  func revert(on database: any Database) async throws {
    try await database.schema("cycle_type_ownership").delete()
  }
}
