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
    
      .field("title", .string, .required)
      .field("content", .string, .required)
      .field("creation_date", .datetime, .required)
      .field("last_activity_date", .datetime, .required)

      .field("id_user", .uuid, .required, .references("users", "id"))
      .field("id_forum_category", .uuid, .required, .references("forum_categories", "id"))

      .create()
  }
  
  func revert(on database: any Database) async throws {
    try await database.schema("forum_posts").delete()
  }
}
