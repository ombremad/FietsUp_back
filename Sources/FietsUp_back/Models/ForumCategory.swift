import Fluent

import struct Foundation.UUID

final class ForumCategory: Model, @unchecked Sendable {
  static let schema = "forum_categories"

  @ID(key: .id) var id: UUID?

  @Field(key: "name") var name: String
  @Field(key: "details") var details: String?

  @Children(for: \.$forumCategory) var forumPosts: [ForumPost]

  init() {}
  
  convenience init(from dto: CreateForumCategoryDTO) {
    self.init()
    
    // user provided
    self.name = dto.name.trimmingCharacters(in: .whitespacesAndNewlines)
    self.details = dto.details?.trimmingCharacters(in: .whitespacesAndNewlines)
  }
}

extension ForumCategory {
  func patch(with dto: PatchForumCategoryDTO) {
    if let name = dto.name { self.name = name.trimmingCharacters(in: .whitespacesAndNewlines) }
    if let details = dto.details { self.details = details?.trimmingCharacters(in: .whitespacesAndNewlines) }
  }
}
