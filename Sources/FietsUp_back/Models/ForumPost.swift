import Fluent

import struct Foundation.UUID

final class ForumPost: Model, @unchecked Sendable {
  static let schema = "forum_posts"

  @ID(key: .id) var id: UUID?
  @Field(key: "title") var title: String
  @Field(key: "content") var content: String
  @OptionalField(key: "last_activity_date") var lastActivityDate: Date?

  @Timestamp(key: "creation_date", on: .create) var creationDate: Date?

  @Parent(key: "id_user") var user: User
  @Parent(key: "id_forum_category") var forumCategory: ForumCategory

  @Children(for: \.$forumPost) var forumComments: [ForumComment]
  @Children(for: \.$forumPost) var forumPostReports: [ForumPostReport]

  @Siblings(through: ForumPostFav.self, from: \.$forumPost, to: \.$user) var usersFaved: [User]
  @Siblings(through: ForumPostLike.self, from: \.$forumPost, to: \.$user) var usersLiked: [User]

  init() {}
  
  convenience init(from dto: CreateForumPostDTO, userID: UUID, forumCategoryID: UUID) {
    self.init()
    
    // computed
    self.$user.id = userID
    self.$forumCategory.id = forumCategoryID

    // user provided
    self.title = dto.title.trimmingCharacters(in: .whitespacesAndNewlines)
    self.content = dto.content.trimmingCharacters(in: .whitespacesAndNewlines)
  }
}

extension ForumPost {
  func patch(with dto: PatchForumPostDTO) {
    if let title = dto.title {
      self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    if let content = dto.content {
      self.content = content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
  }
}
