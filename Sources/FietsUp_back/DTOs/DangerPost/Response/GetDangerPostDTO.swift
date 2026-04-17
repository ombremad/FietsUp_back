//
//  GetDangerPostDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 26/03/2026.
//

import Vapor
import Fluent

struct GetDangerPostDTO: Content {
  var id: UUID
  var title: String
  var content: String
  var latitude: Double
  var longitude: Double
  var user: GetUserPublicDTO
  var creationDate: Date?
  var dangerCategory: GetDangerCategoryDTO
  var likeCount: Int
  var likedByUser: Bool
  var favedByUser: Bool
  var comments: [GetDangerCommentDTO]
}

extension GetDangerPostDTO {
  init(from model: DangerPost, likeCount: Int, likedByUser: Bool, favedByUser: Bool, commentsDTOs: [GetDangerCommentDTO]) throws {
    guard let id = model.id else { throw Abort(.internalServerError) }
    
    self.init(
      id: id,
      title: model.title,
      content: model.content,
      latitude: model.latitude,
      longitude: model.longitude,
      user: try GetUserPublicDTO(from: model.user),
      creationDate: model.creationDate,
      dangerCategory: try GetDangerCategoryDTO(from: model.dangerCategory),
      likeCount: likeCount,
      likedByUser: likedByUser,
      favedByUser: favedByUser,
      comments: commentsDTOs
    )
  }
}

func populateDangerPostDTO(from dangerPost: DangerPost, userID: UUID, on db: any Database) async throws -> GetDangerPostDTO {
  
  async let likeCount = DangerPostLike.query(on: db)
    .filter(\.$dangerPost.$id == dangerPost.requireID())
    .count()
  
  async let likedByUser = (
    DangerPostLike.query(on: db)
      .filter(\.$dangerPost.$id == dangerPost.requireID())
      .filter(\.$user.$id == userID)
      .count()
  ) > 0
  
  async let favedByUser = (
    DangerPostFav.query(on: db)
      .filter(\.$dangerPost.$id == dangerPost.requireID())
      .filter(\.$user.$id == userID)
      .count()
  ) > 0
  
  async let commentsDTOs = try await populateDangerCommentsDTOs(from: dangerPost.dangerComments, userID: userID, on: db)
  
  return try await GetDangerPostDTO(from: dangerPost, likeCount: likeCount, likedByUser: likedByUser, favedByUser: favedByUser, commentsDTOs: commentsDTOs)
}
