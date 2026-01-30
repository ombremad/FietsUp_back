import Fluent
import struct Foundation.UUID

final class ForumPost: Model, @unchecked Sendable {
    static let schema = "forum_posts"
    
    @ID(key: .id) var id: UUID?
    
    @Field(key: "title") var title: String
    @Field(key: "content") var content: String
    @Field(key: "creation_date") var creationDate: Date
    
    @Parent(key: "id_user") var user: User
    @Parent(key: "id_forum_category") var forumCategory: ForumCategory
    
    @Children(for: \.$forumPost) var forumComments: [ForumComment]
    @Children(for: \.$forumPost) var forumPostReports: [ForumPostReport]
    
    @Siblings(through: ForumPostFav.self, from: \.$forumPost, to: \.$user) var usersFaved: [User]
    @Siblings(through: ForumPostLike.self, from: \.$forumPost, to: \.$user) var usersLiked: [User]

    init() { }
}
