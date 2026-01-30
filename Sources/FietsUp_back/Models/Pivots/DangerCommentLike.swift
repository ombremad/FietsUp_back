import Fluent
import struct Foundation.UUID

final class DangerCommentLike: Model, @unchecked Sendable {
    static let schema = "danger_comment_likes"
    
    @ID(key: .id) var id: UUID?
        
    @Parent(key: "id_user") var user: User
    @Parent(key: "id_danger_comment") var dangerComment: DangerComment

    init() { }
}
