//
//  GetAllReportsDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 08/07/2026.
//

import Vapor

struct GetAllReportsDTO: Content {
  var forumPosts: [GetForumPostReportDTO]
  var forumComments: [GetForumCommentReportDTO]
  var dangerPosts: [GetDangerPostReportDTO]
  var dangerComments: [GetDangerCommentReportDTO]
}

extension GetAllReportsDTO {
  init(
    forumPosts: [ForumPostReport],
    forumComments: [ForumCommentReport],
    dangerPosts: [DangerPostReport],
    dangerComments: [DangerCommentReport]
  ) throws {
    self.init(
      forumPosts: try forumPosts.map { try GetForumPostReportDTO(from: $0) },
      forumComments: try forumComments.map { try GetForumCommentReportDTO(from: $0) },
      dangerPosts: try dangerPosts.map { try GetDangerPostReportDTO(from: $0) },
      dangerComments: try dangerComments.map { try GetDangerCommentReportDTO(from: $0) }
    )
  }
}
