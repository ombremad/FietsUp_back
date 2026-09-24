//
//  CreateCycleTypes.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 24/09/2026.
//

import Fluent

struct CreateCycleTypes: AsyncMigration {
  func prepare(on database: any Database) async throws {
    try await database.schema("cycle_types")
      .id()
    
      .field("name", .string, .required)
      .field("file_link", .string, .required)
    
      .unique(on: "name")
    
      .create()
  }
  
  func revert(on database: any Database) async throws {
    try await database.schema("cycle_types").delete()
  }
}
