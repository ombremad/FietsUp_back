import Fluent

import struct Foundation.UUID

final class DangerComment: Model, @unchecked Sendable {
  static let schema = "danger_comments"

  @ID(key: .id) var id: UUID?

  @Field(key: "content") var content: String

  @Timestamp(key: "creation_date", on: .create) var creationDate: Date?

  @Parent(key: "id_user") var user: User
  @Parent(key: "id_danger_post") var dangerPost: DangerPost

  @Children(for: \.$dangerComment) var dangerCommentReports: [DangerCommentReport]

  @Siblings(through: DangerCommentFav.self, from: \.$dangerComment, to: \.$user) var usersFaved:
    [User]
  @Siblings(through: DangerCommentLike.self, from: \.$dangerComment, to: \.$user) var usersLiked:
    [User]

  init() {}
  
  convenience init(from dto: CreateDangerCommentDTO, userID: UUID, dangerPostID: UUID) {
    self.init()
    
    // computed
    self.$user.id = userID
    self.$dangerPost.id = dangerPostID

    // user provided
    self.content = dto.content.trimmingCharacters(in: .whitespacesAndNewlines)
  }
}

extension DangerComment {
  func patch(with dto: PatchDangerCommentDTO) {
    if let content = dto.content { self.content = content.trimmingCharacters(in: .whitespacesAndNewlines) }
  }
}
