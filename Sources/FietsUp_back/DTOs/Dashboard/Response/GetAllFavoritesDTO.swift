//
//  GetFavoritesDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 13/09/2026.
//

import Vapor

struct GetAllFavoritesDTO: Content {
  var forumPosts: [GetForumPostShortDTO]
  var forumComments: [GetForumCommentShortDTO]
  var dangerPosts: [GetDangerPostShortDTO]
  var dangerComments: [GetDangerCommentShortDTO]
}

extension GetAllFavoritesDTO {
  init(
    forumPosts: [ForumPost],
    forumComments: [ForumComment],
    dangerPosts: [DangerPost],
    dangerComments: [DangerComment]
  ) throws {
    self.init(
      forumPosts: try forumPosts.map { try GetForumPostShortDTO(from: $0) },
      forumComments: try forumComments.map { try GetForumCommentShortDTO(from: $0) },
      dangerPosts: try dangerPosts.map { try GetDangerPostShortDTO(from: $0) },
      dangerComments: try dangerComments.map { try GetDangerCommentShortDTO(from: $0) }
    )
  }
}
