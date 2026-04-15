import Fluent

import struct Foundation.UUID

final class ForumCommentFav: Model, @unchecked Sendable {
  static let schema = "forum_comment_favs"

  @ID(key: .id) var id: UUID?

  @Parent(key: "id_user") var user: User
  @Parent(key: "id_forum_comment") var forumComment: ForumComment

  init() {}
  
  convenience init(userID: UUID, forumCommentID: UUID) {
    self.init()
    
      // computed
    self.$user.id = userID
    self.$forumComment.id = forumCommentID
  }
}
