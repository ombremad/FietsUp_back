import Fluent
import struct Foundation.UUID

final class ForumComment: Model, @unchecked Sendable {
    static let schema = "forum_comments"
    
    @ID(key: .id) var id: UUID?
    
    @Field(key: "content") var content: String
    @Field(key: "creation_date") var creationDate: Date
    
    @Parent(key: "id_user") var user: User
    @Parent(key: "id_forum_post") var forumPost: ForumPost
    
    @Children(for: \.$forumComment) var forumCommentReports: [ForumCommentReport]
    
    @Siblings(through: ForumCommentFav.self, from: \.$forumComment, to: \.$user) var usersFaved: [User]
    @Siblings(through: ForumCommentLike.self, from: \.$forumComment, to: \.$user) var usersLiked: [User]

    init() { }
}
