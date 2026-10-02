//
//  CreateDangerCommentFavs.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 02/10/2026.
//

import Fluent

struct CreateDangerCommentFavs: AsyncMigration {
  func prepare(on database: any Database) async throws {
    try await database.schema("danger_comment_favs")
      .id()

      .field("id_user", .uuid, .required, .references("users", "id", onDelete: .cascade))
      .field("id_danger_comment", .uuid, .required, .references("danger_comments", "id", onDelete: .cascade))

      .unique(on: "id_user", "id_danger_comment")

      .create()
  }

  func revert(on database: any Database) async throws {
    try await database.schema("danger_comment_favs").delete()
  }
}
