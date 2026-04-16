import Fluent

import struct Foundation.UUID

final class DangerCommentReport: Model, @unchecked Sendable {
  static let schema = "danger_comment_reports"

  @ID(key: .id) var id: UUID?

  @OptionalField(key: "details") var details: String?
  @OptionalField(key: "process_details") var processDetails: String?
  @Field(key: "creation_date") var creationDate: Date
  @OptionalField(key: "process_date") var processDate: Date?

  @OptionalParent(key: "id_danger_comment") var dangerComment: DangerComment?
  @Parent(key: "id_user") var user: User
  @Parent(key: "id_moderation_category") var moderationCategory: ModerationCategory

  init() {}
}
