//
//  CreateForumPostLikes.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 02/10/2026.
//

import Fluent

struct CreateForumPostLikes: AsyncMigration {
  func prepare(on database: any Database) async throws {
    try await database.schema("forum_post_likes")
      .id()

      .field("id_user", .uuid, .required, .references("users", "id", onDelete: .cascade))
      .field("id_forum_post", .uuid, .required, .references("forum_posts", "id", onDelete: .cascade))

      .unique(on: "id_user", "id_forum_post")

      .create()
  }

  func revert(on database: any Database) async throws {
    try await database.schema("forum_post_likes").delete()
  }
}
