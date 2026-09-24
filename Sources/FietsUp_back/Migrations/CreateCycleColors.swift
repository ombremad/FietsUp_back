//
//  CreateCycleColors.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 24/09/2026.
//

import Fluent

struct CreateCycleColors: AsyncMigration {
  func prepare(on database: any Database) async throws {
    try await database.schema("cycle_colors")
      .id()
    
      .field("name", .string, .required)
      .field("color", .string, .required)
    
      .unique(on: "name")
    
      .create()
  }
  
  func revert(on database: any Database) async throws {
    try await database.schema("cycle_colors").delete()
  }
}
