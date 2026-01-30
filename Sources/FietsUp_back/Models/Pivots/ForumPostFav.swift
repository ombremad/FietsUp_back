import Fluent
import struct Foundation.UUID

final class ForumPostFav: Model, @unchecked Sendable {
    static let schema = "forum_post_favs"
    
    @ID(key: .id) var id: UUID?
        
    @Parent(key: "id_user") var user: User
    @Parent(key: "id_forum_post") var forumPost: ForumPost

    init() { }
}
