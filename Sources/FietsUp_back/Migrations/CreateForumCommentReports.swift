//
//  CreateForumCommentReports.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 24/09/2026.
//

import Fluent

struct CreateForumCommentReports: AsyncMigration {
  func prepare(on database: any Database) async throws {
    try await database.schema("forum_comment_reports")
      .id()

      .field("details", .sql(unsafeRaw: "TEXT"))
      .field("process_details", .sql(unsafeRaw: "TEXT"))
      .field("creation_date", .sql(unsafeRaw: "TIMESTAMP"), .required, .sql(unsafeRaw: "DEFAULT CURRENT_TIMESTAMP"))
      .field("process_date", .sql(unsafeRaw: "TIMESTAMP NULL"))

      .field("id_forum_comment", .uuid, .references("forum_comments", "id", onDelete: .setNull))
      .field("id_user", .uuid, .required, .references("users", "id", onDelete: .cascade))
      .field("id_moderation_category", .uuid, .required, .references("moderation_categories", "id", onDelete: .cascade))

      .create()
  }

  func revert(on database: any Database) async throws {
    try await database.schema("forum_comment_reports").delete()
  }
}
