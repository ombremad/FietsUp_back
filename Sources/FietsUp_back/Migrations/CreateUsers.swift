//
//  CreateUsers.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 02/10/2026.
//

import Fluent

struct CreateUsers: AsyncMigration {
  func prepare(on database: any Database) async throws {
    try await database.schema("users")
      .id()
    
      .field("first_name", .string, .required)
      .field("last_name", .string, .required)
      .field("nickname", .string, .required)
      .field("email", .string, .required)
      .field("password", .string, .required)
      .field("creation_date", .datetime, .required)
      .field("ban_end_date", .datetime)
      .field("admin_rights", .int, .required)
      .field("bio", .string)
      .field("streak", .int, .required)
      .field("streak_updated_this_week", .bool, .required)
      .field("total_elapsed_distance", .int, .required)
    
      .field("id_cycle_type", .uuid, .references("cycle_types", "id"))
      .field("id_cycle_color", .uuid, .references("cycle_colors", "id"))
      .field("id_cycle_decoration", .uuid, .references("cycle_decorations", "id"))
    
      .create()
  }
  
  func revert(on database: any Database) async throws {
    try await database.schema("users").delete()
  }
}

