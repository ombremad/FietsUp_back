import Fluent

import struct Foundation.UUID

final class DangerCommentFav: Model, @unchecked Sendable {
  static let schema = "danger_comment_favs"

  @ID(key: .id) var id: UUID?

  @Parent(key: "id_user") var user: User
  @Parent(key: "id_danger_comment") var dangerComment: DangerComment

  init() {}
  
  convenience init(userID: UUID, dangerCommentID: UUID) {
    self.init()
    
      // computed
    self.$user.id = userID
    self.$dangerComment.id = dangerCommentID
  }
}
