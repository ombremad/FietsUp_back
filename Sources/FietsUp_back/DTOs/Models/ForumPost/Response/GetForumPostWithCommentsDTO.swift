//
//  GetForumPostDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 26/03/2026.
//

import Vapor
import Fluent

struct GetForumPostWithCommentsDTO: Content {
  var id: UUID
  var title: String
  var content: String
  var user: GetUserPublicDTO
  var creationDate: Date?
  var likeCount: Int
  var likedByUser: Bool
  var favedByUser: Bool
  var comments: Page<GetForumCommentDTO>
}

extension GetForumPostWithCommentsDTO {
  init(from model: ForumPost, likeCount: Int, likedByUser: Bool, favedByUser: Bool, commentsPage: Page<GetForumCommentDTO>) throws {
    guard let id = model.id else { throw Abort(.internalServerError) }
    
    self.init(
      id: id,
      title: model.title,
      content: model.content,
      user: try GetUserPublicDTO(from: model.user),
      creationDate: model.creationDate,
      likeCount: likeCount,
      likedByUser: likedByUser,
      favedByUser: favedByUser,
      comments: commentsPage
    )
  }
}

func populateForumPostDTO(from forumPost: ForumPost, userID: UUID, req: Request) async throws -> GetForumPostWithCommentsDTO {
  async let likeCount = ForumPostLike.query(on: req.db)
    .filter(\.$forumPost.$id == forumPost.requireID())
    .count()
  
  async let likedByUser = (
    ForumPostLike.query(on: req.db)
      .filter(\.$forumPost.$id == forumPost.requireID())
      .filter(\.$user.$id == userID)
      .count()
  ) > 0
  
  async let favedByUser = (
    ForumPostFav.query(on: req.db)
      .filter(\.$forumPost.$id == forumPost.requireID())
      .filter(\.$user.$id == userID)
      .count()
  ) > 0
  
  let commentsPage = try await ForumComment.query(on: req.db)
    .filter(\.$forumPost.$id == forumPost.requireID())
    .sort(\.$creationDate, .ascending)
    .with(\.$user) { $0.withCycle() }
    .paginate(for: req)
  
  let commentsDTOs = try await populateForumCommentsDTOs(from: commentsPage.items, userID: userID, on: req.db)
  let commentsDTOPage = Page(items: commentsDTOs, metadata: commentsPage.metadata)
  
  return try await GetForumPostWithCommentsDTO(from: forumPost, likeCount: likeCount, likedByUser: likedByUser, favedByUser: favedByUser, commentsPage: commentsDTOPage)
}
