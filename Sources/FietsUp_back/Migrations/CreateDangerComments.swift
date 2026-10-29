//
//  CreateDangerComments.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 24/09/2026.
//

import Fluent

struct CreateDangerComments: AsyncMigration {
  func prepare(on database: any Database) async throws {
    try await database.schema("danger_comments")
      .id()
      .field("content", .sql(unsafeRaw: "TEXT"), .required)
      .field("creation_date", .sql(unsafeRaw: "TIMESTAMP"), .required, .sql(unsafeRaw: "DEFAULT CURRENT_TIMESTAMP"))

      .field("id_user", .uuid, .required, .references("users", "id", onDelete: .cascade))
      .field("id_danger_post", .uuid, .required, .references("danger_posts", "id", onDelete: .cascade))

      .create()
  }

  func revert(on database: any Database) async throws {
    try await database.schema("danger_comments").delete()
  }
}
