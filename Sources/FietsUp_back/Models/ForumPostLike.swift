import Fluent

import struct Foundation.UUID

final class ForumPostLike: Model, @unchecked Sendable {
  static let schema = "forum_post_likes"

  @ID(key: .id) var id: UUID?

  @Parent(key: "id_user") var user: User
  @Parent(key: "id_forum_post") var forumPost: ForumPost

  init() {}
  
  convenience init(userID: UUID, forumPostID: UUID) {
    self.init()
    
      // computed
    self.$user.id = userID
    self.$forumPost.id = forumPostID
  }
}
