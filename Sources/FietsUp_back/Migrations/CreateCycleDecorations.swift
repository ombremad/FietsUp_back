//
//  CreateCycleDecorations.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 24/09/2026.
//

import Fluent

struct CreateCycleDecorations: AsyncMigration {
  func prepare(on database: any Database) async throws {
    try await database.schema("cycle_decorations")
      .id()
    
      .field("name", .sql(unsafeRaw: "VARCHAR(50)"), .required)
      .field("file_link", .sql(unsafeRaw: "VARCHAR(100)"), .required)
    
      .unique(on: "name")
    
      .create()
  }
  
  func revert(on database: any Database) async throws {
    try await database.schema("cycle_decorations").delete()
  }
}
