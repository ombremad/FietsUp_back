//
//  CreateDangerPosts.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 24/09/2026.
//

import Fluent
import FluentMySQLDriver

struct CreateDangerPosts: AsyncMigration {
  func prepare(on database: any Database) async throws {
    let builder = database.schema("danger_posts")
      .id()

      .field("title", .sql(unsafeRaw: "VARCHAR(100)"), .required)
      .field("content", .sql(unsafeRaw: "TEXT"), .required)
      .field("creation_date", .sql(unsafeRaw: "TIMESTAMP"), .required, .sql(unsafeRaw: "DEFAULT CURRENT_TIMESTAMP"))
      .field("latitude", .sql(unsafeRaw: "DECIMAL(8,6)"), .required)
      .field("longitude", .sql(unsafeRaw: "DECIMAL(9,6)"), .required)
      .field("last_activity_date", .sql(unsafeRaw: "TIMESTAMP"), .required, .sql(unsafeRaw: "DEFAULT CURRENT_TIMESTAMP"))

      .field("id_user", .uuid, .required, .references("users", "id", onDelete: .cascade))
      .field("id_danger_category", .uuid, .required, .references("danger_categories", "id", onDelete: .cascade))

    if database is any MySQLDatabase {
      builder.field("location", .sql(unsafeRaw: "POINT"), .required)
    }

    try await builder.create()
  }

  func revert(on database: any Database) async throws {
    try await database.schema("danger_posts").delete()
  }
}
