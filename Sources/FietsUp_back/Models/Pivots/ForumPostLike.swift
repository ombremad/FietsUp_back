import Fluent
import struct Foundation.UUID

final class ForumPostLike: Model, @unchecked Sendable {
    static let schema = "forum_post_like"
    
    @ID(key: .id) var id: UUID?
        
    @Parent(key: "id_user") var user: User
    @Parent(key: "id_forum_post") var forumPost: ForumPost

    init() { }
}
