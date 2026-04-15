import Fluent

import struct Foundation.UUID

final class ModerationCategory: Model, @unchecked Sendable {
  static let schema = "moderation_categories"

  @ID(key: .id) var id: UUID?

  @Field(key: "name") var name: String

  @Children(for: \.$moderationCategory) var dangerCommentReports: [DangerCommentReport]
  @Children(for: \.$moderationCategory) var dangerPostReports: [DangerPostReport]
  @Children(for: \.$moderationCategory) var forumCommentReports: [ForumCommentReport]
  @Children(for: \.$moderationCategory) var forumPostReports: [ForumPostReport]

  init() {}
  
  convenience init(from dto: CreateModerationCategoryDTO) {
    self.init()
    
      // user provided
    self.name = dto.name.trimmingCharacters(in: .whitespacesAndNewlines)
  }
}

extension ModerationCategory {
  func patch(with dto: PatchModerationCategoryDTO) {
    if let name = dto.name { self.name = name.trimmingCharacters(in: .whitespacesAndNewlines) }
  }
}
