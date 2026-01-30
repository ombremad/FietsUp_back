import Fluent
import struct Foundation.UUID

final class ForumPostReport: Model, @unchecked Sendable {
    static let schema = "forum_post_reports"
    
    @ID(key: .id) var id: UUID?
    
    @Field(key: "description") var description: String
    @Field(key: "process_description") var processDescription: String?
    @Field(key: "creation_date") var creationDate: Date
    @Field(key: "process_date") var processDate: Date?
    
    @Parent(key: "id_forum_post") var forumPost: ForumPost
    @Parent(key: "id_user") var user: User
    @Parent(key: "id_moderation_category") var moderationCategory: ModerationCategory

    init() { }
}
