import Fluent
import struct Foundation.UUID

final class DangerComment: Model, @unchecked Sendable {
    static let schema = "danger_comment"
    
    @ID(key: .id) var id: UUID?
    
    @Field(key: "content") var content: String
    @Field(key: "creation_date") var creationDate: Date
    
    @Parent(key: "id_user") var user: User
    @Parent(key: "id_danger_post") var dangerPost: DangerPost
    
    @Children(for: \.$dangerComment) var dangerCommentReports: [DangerCommentReport]
    
    @Siblings(through: DangerCommentFav.self, from: \.$dangerComment, to: \.$user) var usersFaved: [User]
    @Siblings(through: DangerCommentLike.self, from: \.$dangerComment, to: \.$user) var usersLiked: [User]

    init() { }
}
