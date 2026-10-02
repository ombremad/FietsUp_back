//
//  CreateForumPostReports.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 02/10/2026.
//

import Fluent

struct CreateForumPostReports: AsyncMigration {
  func prepare(on database: any Database) async throws {
    try await database.schema("forum_post_reports")
      .id()

      .field("details", .string)
      .field("process_details", .string)
      .field("creation_date", .datetime, .required)
      .field("process_date", .datetime)

      .field("id_forum_post", .uuid, .references("forum_posts", "id", onDelete: .setNull))
      .field("id_user", .uuid, .required, .references("users", "id", onDelete: .cascade))
      .field("id_moderation_category", .uuid, .required, .references("moderation_categories", "id", onDelete: .cascade))

      .create()
  }

  func revert(on database: any Database) async throws {
    try await database.schema("forum_post_reports").delete()
  }
}
