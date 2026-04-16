//
//  FindDangerPost.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 13/04/2026.
//

import Vapor
import Fluent

func findDangerPost(id: UUID, on db: any Database) async throws -> DangerPost {
  let query = DangerPost.query(on: db)
    .filter(\.$id == id)
    .with(\.$user)
    .with(\.$dangerCategory)
    .with(\.$dangerComments) { $0.with(\.$user) }
  
  guard let post = try await query.first() else {
    throw Abort(.notFound, reason: "DangerPost not found")
  }
  
  post.$dangerComments.value = post.$dangerComments.value?
    .filter { $0.creationDate != nil }
    .sorted { $0.creationDate! > $1.creationDate! }
  
  return post
}
