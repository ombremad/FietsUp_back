//
//  CountForumComments.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 14/04/2026.
//

import Vapor
import Fluent
import SQLKit

func countForumComments(for posts: [ForumPost], on db: any Database) async throws -> [UUID: Int] {
  guard !posts.isEmpty else { return [:] }
  guard let sql = db as? any SQLDatabase else { throw Abort(.internalServerError) }
  
  let idList = try posts
    .map { "UNHEX('\(try $0.requireID().hexString)')" }
    .joined(separator: ", ")
  
  let rows = try await sql.raw("""
        SELECT HEX(id_forum_post) as id_forum_post, COUNT(*) as total_comments
        FROM \(unsafeRaw: ForumComment.schema)
        WHERE id_forum_post IN (\(unsafeRaw: idList))
        GROUP BY id_forum_post
        """).all()
  
  return try Dictionary(uniqueKeysWithValues: rows.map {
    let hex = try $0.decode(column: "id_forum_post", as: String.self)
    guard let uuid = UUID(hex: hex) else { throw Abort(.internalServerError) }
    return (uuid, try $0.decode(column: "total_comments", as: Int.self))
  })
}
