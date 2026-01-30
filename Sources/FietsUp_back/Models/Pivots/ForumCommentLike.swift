import Fluent
import struct Foundation.UUID

final class ForumCommentLike: Model, @unchecked Sendable {
    static let schema = "forum_comment_likes"
    
    @ID(key: .id) var id: UUID?
        
    @Parent(key: "id_user") var user: User
    @Parent(key: "id_forum_comment") var forumComment: ForumComment

    init() { }
}
