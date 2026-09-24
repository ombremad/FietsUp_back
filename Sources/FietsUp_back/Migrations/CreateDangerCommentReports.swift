//
//  CreateDangerCommentReports.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 24/09/2026.
//

import Fluent

struct CreateDangerCommentReports: AsyncMigration {
  func prepare(on database: any Database) async throws {
    try await database.schema("danger_comment_reports")
      .id()
    
      .field("details", .string)
      .field("process_details", .string)
      .field("creation_date", .datetime, .required)
      .field("process_date", .datetime)
    
      .field("id_danger_comment", .uuid, .required, .references("danger_comments", "id"))
      .field("id_user", .uuid, .required, .references("users", "id"))
      .field("id_moderation_category", .uuid, .required, .references("moderation_categories", "id"))
    
      .create()
  }
    
  func revert(on database: any Database) async throws {
    try await database.schema("danger_comment_reports").delete()
  }
}
