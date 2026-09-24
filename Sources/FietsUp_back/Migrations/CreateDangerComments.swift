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
      .field("content", .string, .required)
      .field("creation_date", .datetime, .required)
    
      .field("id_user", .uuid, .required, .references("users", "id"))
      .field("id_danger_post", .uuid, .required, .references("danger_posts", "id"))

      .create()
  }
  
  func revert(on database: any Database) async throws {
    try await database.schema("danger_comments").delete()
  }
}
