import Fluent
import struct Foundation.UUID

final class DangerPostReport: Model, @unchecked Sendable {
    static let schema = "danger_post_reports"
    
    @ID(key: .id) var id: UUID?
    
    @Field(key: "description") var description: String
    @Field(key: "process_description") var processDescription: String?
    @Field(key: "creation_date") var creationDate: Date
    @Field(key: "process_date") var processDate: Date?
    
    @Parent(key: "id_danger_post") var dangerPost: DangerPost
    @Parent(key: "id_user") var user: User
    @Parent(key: "id_moderation_category") var moderationCategory: ModerationCategory

    init() { }
}
