import Fluent

import struct Foundation.UUID

final class ForumPostReport: Model, @unchecked Sendable {
  static let schema = "forum_post_reports"

  @ID(key: .id) var id: UUID?

  @OptionalField(key: "details") var details: String?
  @OptionalField(key: "process_details") var processDetails: String?
  @Timestamp(key: "creation_date", on: .create) var creationDate: Date?
  @OptionalField(key: "process_date") var processDate: Date?

  @OptionalParent(key: "id_forum_post") var forumPost: ForumPost?
  @Parent(key: "id_user") var user: User
  @Parent(key: "id_moderation_category") var moderationCategory: ModerationCategory

  init() {}
  
  convenience init(from dto: CreateReportDTO, userID: UUID, forumPostID: UUID) {
    self.init()
    
      // computed
    self.$user.id = userID
    self.$forumPost.id = forumPostID
    
      // user provided
    if let details = dto.details {
      self.details = details.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    self.$moderationCategory.id = dto.categoryID
  }
}

extension ForumPostReport {
  func process(with dto: ProcessReportDTO) {
    processDetails = dto.details.trimmingCharacters(in: .whitespacesAndNewlines)
    processDate = .now
  }
}
