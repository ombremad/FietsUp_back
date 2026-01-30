import Fluent
import struct Foundation.UUID

final class ForumCategory: Model, @unchecked Sendable {
    static let schema = "forum_categories"
    
    @ID(key: .id) var id: UUID?
    
    @Field(key: "name") var name: String
    @Field(key: "description") var description: String?
    
    @Children(for: \.$forumCategory) var forumPosts: [ForumPost]

    init() { }
}
