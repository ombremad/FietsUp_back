//
//  CreateForumComments.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 24/09/2026.
//

import Fluent

struct CreateForumComments: AsyncMigration {
  func prepare(on database: any Database) async throws {
    try await database.schema("forum_comments")
      .id()
    
      .field("content", .string, .required)
      .field("creation_date", .datetime, .required)

      .field("id_user", .uuid, .required, .references("users", "id"))
      .field("id_forum_post", .uuid, .required, .references("forum_posts", "id"))

      .create()
  }
  
  func revert(on database: any Database) async throws {
    try await database.schema("forum_comments").delete()
  }
}
