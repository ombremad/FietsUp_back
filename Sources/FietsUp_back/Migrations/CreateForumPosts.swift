//
//  CreateForumPosts.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 24/09/2026.
//

import Fluent

struct CreateForumPosts: AsyncMigration {
  func prepare(on database: any Database) async throws {
    try await database.schema("forum_posts")
      .id()

      .field("title", .sql(unsafeRaw: "VARCHAR(100)"), .required)
      .field("content", .sql(unsafeRaw: "TEXT"), .required)
      .field("creation_date", .sql(unsafeRaw: "TIMESTAMP"), .required, .sql(unsafeRaw: "DEFAULT CURRENT_TIMESTAMP"))
      .field("last_activity_date", .sql(unsafeRaw: "TIMESTAMP"), .required, .sql(unsafeRaw: "DEFAULT CURRENT_TIMESTAMP"))

      .field("id_user", .uuid, .required, .references("users", "id", onDelete: .cascade))
      .field("id_forum_category", .uuid, .required, .references("forum_categories", "id", onDelete: .cascade))

      .create()
  }

  func revert(on database: any Database) async throws {
    try await database.schema("forum_posts").delete()
  }
}
