//
//  CreateForumCommentFavs.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 02/10/2026.
//

import Fluent

struct CreateForumCommentFavs: AsyncMigration {
  func prepare(on database: any Database) async throws {
    try await database.schema("forum_comment_favs")
      .id()

      .field("id_user", .uuid, .required, .references("users", "id", onDelete: .cascade))
      .field("id_forum_comment", .uuid, .required, .references("forum_comments", "id", onDelete: .cascade))

      .unique(on: "id_user", "id_forum_comment")

      .create()
  }

  func revert(on database: any Database) async throws {
    try await database.schema("forum_comment_favs").delete()
  }
}
