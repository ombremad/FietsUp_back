import Fluent
import struct Foundation.UUID

final class DangerPostLike: Model, @unchecked Sendable {
    static let schema = "danger_post_likes"
    
    @ID(key: .id) var id: UUID?
        
    @Parent(key: "id_user") var user: User
    @Parent(key: "id_danger_post") var dangerPost: DangerPost

    init() { }
}
