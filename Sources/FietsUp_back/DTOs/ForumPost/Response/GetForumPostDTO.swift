//
//  GetForumPostDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 26/03/2026.
//

import Vapor
import Fluent

struct GetForumPostDTO: Content {
  var id: UUID
  var title: String
  var content: String
  var user: GetUserShortDTO
  var creationDate: Date?
  var likeCount: Int
  var likedByUser: Bool
  var favedByUser: Bool
  var comments: [GetForumCommentDTO]
}

extension GetForumPostDTO {
  init(from model: ForumPost, userID: UUID, on db: any Database) async throws {
    guard let id = model.id else { throw Abort(.internalServerError) }
    
    async let likeCount = ForumPostLike.query(on: db)
      .filter(\.$forumPost.$id == id)
      .count()
    async let likedByUser = ForumPostLike.query(on: db)
      .filter(\.$forumPost.$id == id)
      .filter(\.$user.$id == userID)
      .count()
    async let favedByUser = ForumPostFav.query(on: db)
      .filter(\.$forumPost.$id == id)
      .filter(\.$user.$id == userID)
      .count()
    
    self.init(
      id: id,
      title: model.title,
      content: model.content,
      user: try GetUserShortDTO(from: model.user),
      creationDate: model.creationDate,
      likeCount: try await likeCount,
      likedByUser: try await likedByUser > 0,
      favedByUser: try await favedByUser > 0,
      
      // TODO: actually populate comments counts
      comments: try model.forumComments.map { try GetForumCommentDTO(from: $0, likeCount: 0, likedByUser: false, favedByUser: false) }
    )
  }
}
