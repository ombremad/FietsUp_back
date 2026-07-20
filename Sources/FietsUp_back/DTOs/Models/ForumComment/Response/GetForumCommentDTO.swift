//
//  GetFormCommentDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 26/03/2026.
//

import Vapor
import Fluent
import SQLKit

struct GetForumCommentDTO: Content {
  var id: UUID
  var content: String
  var user: GetUserPublicDTO
  var creationDate: Date?
  var likeCount: Int
  var likedByUser: Bool
  var favedByUser: Bool
}

extension GetForumCommentDTO {
  init(from model: ForumComment, likeCount: Int, likedByUser: Bool, favedByUser: Bool) throws {
    guard let id = model.id else { throw Abort(.internalServerError) }
    
    self.init(
      id: id,
      content: model.content,
      user: try GetUserPublicDTO(from: model.user),
      creationDate: model.creationDate,
      likeCount: likeCount,
      likedByUser: likedByUser,
      favedByUser: favedByUser
    )
  }
}

func populateForumCommentDTO(from forumComment: ForumComment, userID: UUID, on db: any Database) async throws -> GetForumCommentDTO {
  
  async let likeCount = ForumCommentLike.query(on: db)
    .filter(\.$forumComment.$id == forumComment.requireID())
    .count()
  
  async let likedByUser = (
    ForumCommentLike.query(on: db)
      .filter(\.$forumComment.$id == forumComment.requireID())
      .filter(\.$user.$id == userID)
      .count()
  ) > 0
  
  async let favedByUser = (
    ForumCommentFav.query(on: db)
      .filter(\.$forumComment.$id == forumComment.requireID())
      .filter(\.$user.$id == userID)
      .count()
  ) > 0
  
  return try await GetForumCommentDTO(from: forumComment, likeCount: likeCount, likedByUser: likedByUser, favedByUser: favedByUser)
}

func populateForumCommentsDTOs(from comments: [ForumComment], userID: UUID, on db: any Database) async throws -> [GetForumCommentDTO] {
  guard !comments.isEmpty else { return [] }
  
  let commentIDs = try comments.map { try $0.requireID() }
  let idList = commentIDs.map { "UNHEX('\($0.hexString)')" }.joined(separator: ", ")
  let userHex = userID.hexString
  
  guard let sql = db as? any SQLDatabase else { throw Abort(.internalServerError) }
  
  async let likeCounts: [UUID: Int] = {
    let rows = try await sql.raw("""
            SELECT HEX(id_forum_comment) as id, COUNT(*) as total
            FROM \(unsafeRaw: ForumCommentLike.schema)
            WHERE id_forum_comment IN (\(unsafeRaw: idList))
            GROUP BY id_forum_comment
            """).all()
    return try Dictionary(uniqueKeysWithValues: rows.map {
      let hex = try $0.decode(column: "id", as: String.self)
      guard let uuid = UUID(hex: hex) else { throw Abort(.internalServerError) }
      return (uuid, try $0.decode(column: "total", as: Int.self))
    })
  }()
  
  async let likedIDs: Set<UUID> = {
    let rows = try await sql.raw("""
            SELECT HEX(id_forum_comment) as id
            FROM \(unsafeRaw: ForumCommentLike.schema)
            WHERE id_forum_comment IN (\(unsafeRaw: idList))
            AND id_user = UNHEX('\(unsafeRaw: userHex)')
            """).all()
    return try Set(rows.map {
      let hex = try $0.decode(column: "id", as: String.self)
      guard let uuid = UUID(hex: hex) else { throw Abort(.internalServerError) }
      return uuid
    })
  }()
  
  async let favedIDs: Set<UUID> = {
    let rows = try await sql.raw("""
            SELECT HEX(id_forum_comment) as id
            FROM \(unsafeRaw: ForumCommentFav.schema)
            WHERE id_forum_comment IN (\(unsafeRaw: idList))
            AND id_user = UNHEX('\(unsafeRaw: userHex)')
            """).all()
    return try Set(rows.map {
      let hex = try $0.decode(column: "id", as: String.self)
      guard let uuid = UUID(hex: hex) else { throw Abort(.internalServerError) }
      return uuid
    })
  }()
  
  let (counts, liked, faved) = try await (likeCounts, likedIDs, favedIDs)
  
  var dtos: [GetForumCommentDTO] = []
  for comment in comments {
    let id = try comment.requireID()
    dtos.append(try GetForumCommentDTO(
      from: comment,
      likeCount: counts[id] ?? 0,
      likedByUser: liked.contains(id),
      favedByUser: faved.contains(id)
    ))
  }
  return dtos
}
