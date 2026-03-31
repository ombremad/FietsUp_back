import Fluent

import struct Foundation.UUID

final class DangerPostReport: Model, @unchecked Sendable {
  static let schema = "danger_post_reports"

  @ID(key: .id) var id: UUID?

  @Field(key: "details") var details: String
  @OptionalField(key: "process_details") var processDetails: String?
  @Field(key: "creation_date") var creationDate: Date
  @OptionalField(key: "process_date") var processDate: Date?

  @Parent(key: "id_danger_post") var dangerPost: DangerPost
  @Parent(key: "id_user") var user: User
  @Parent(key: "id_moderation_category") var moderationCategory: ModerationCategory

  init() {}
}
