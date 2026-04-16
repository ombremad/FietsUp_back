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
  init(from model: ForumPost, likeCount: Int, likedByUser: Bool, favedByUser: Bool, commentsDTOs: [GetForumCommentDTO]) throws {
    guard let id = model.id else { throw Abort(.internalServerError) }
    
    self.init(
      id: id,
      title: model.title,
      content: model.content,
      user: try GetUserShortDTO(from: model.user),
      creationDate: model.creationDate,
      likeCount: likeCount,
      likedByUser: likedByUser,
      favedByUser: favedByUser,
      comments: commentsDTOs
    )
  }
}

func populateForumPostDTO(from forumPost: ForumPost, userID: UUID, on db: any Database) async throws -> GetForumPostDTO {
  
  async let likeCount = ForumPostLike.query(on: db)
    .filter(\.$forumPost.$id == forumPost.requireID())
    .count()
  
  async let likedByUser = (
    ForumPostLike.query(on: db)
      .filter(\.$forumPost.$id == forumPost.requireID())
      .filter(\.$user.$id == userID)
      .count()
  ) > 0
  
  async let favedByUser = (
    ForumPostFav.query(on: db)
      .filter(\.$forumPost.$id == forumPost.requireID())
      .filter(\.$user.$id == userID)
      .count()
  ) > 0
  
  async let commentsDTOs = try await populateForumCommentsDTOs(from: forumPost.forumComments, userID: userID, on: db)
  
  return try await GetForumPostDTO(from: forumPost, likeCount: likeCount, likedByUser: likedByUser, favedByUser: favedByUser, commentsDTOs: commentsDTOs)
}
