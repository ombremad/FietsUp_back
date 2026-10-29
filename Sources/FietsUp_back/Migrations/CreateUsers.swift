//
//  CreateUsers.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 02/10/2026.
//

import Fluent

struct CreateUsers: AsyncMigration {
  func prepare(on database: any Database) async throws {
    try await database.schema("users")
      .id()

      .field("first_name", .sql(unsafeRaw: "VARCHAR(50)"), .required)
      .field("last_name", .sql(unsafeRaw: "VARCHAR(50)"), .required)
      .field("nickname", .sql(unsafeRaw: "VARCHAR(50)"), .required)
      .field("email", .sql(unsafeRaw: "VARCHAR(100)"), .required)
      .field("password", .sql(unsafeRaw: "VARCHAR(255)"), .required)
      .field("creation_date", .sql(unsafeRaw: "TIMESTAMP"), .required, .sql(unsafeRaw: "DEFAULT CURRENT_TIMESTAMP"))
      .field("ban_end_date", .sql(unsafeRaw: "TIMESTAMP NULL"))
      .field("admin_rights", .sql(unsafeRaw: "TINYINT"), .required)
      .field("bio", .sql(unsafeRaw: "TEXT"))
      .field("streak", .sql(unsafeRaw: "SMALLINT"), .required, .sql(.default(0)))
      .field("streak_updated_this_week", .sql(unsafeRaw: "TINYINT(1)"), .required, .sql(.default(0)))
      .field("total_elapsed_distance", .sql(unsafeRaw: "INT"), .required, .sql(.default(0)))

      .field("id_cycle_type", .uuid, .references("cycle_types", "id"))
      .field("id_cycle_color", .uuid, .references("cycle_colors", "id"))
      .field("id_cycle_decoration", .uuid, .references("cycle_decorations", "id"))

      .unique(on: "nickname")
      .unique(on: "email")

      .create()
  }

  func revert(on database: any Database) async throws {
    try await database.schema("users").delete()
  }
}
