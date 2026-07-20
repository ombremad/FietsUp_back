//
//  FindForumPost.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 14/04/2026.
//

import Vapor
import Fluent
import SQLKit

func findForumPost(id: UUID, on db: any Database) async throws -> ForumPost {
  let query = ForumPost.query(on: db)
    .filter(\.$id == id)
    .with(\.$user) { $0.withCycle() }
  
  guard let post = try await query.first() else {
    throw Abort(.notFound, reason: "ForumPost not found")
  }
  return post
}
