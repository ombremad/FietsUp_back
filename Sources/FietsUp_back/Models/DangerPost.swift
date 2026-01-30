import Fluent
import struct Foundation.UUID

final class DangerPost: Model, @unchecked Sendable {
    static let schema = "danger_posts"
    
    @ID(key: .id) var id: UUID?
    
    @Field(key: "title") var title: String
    @Field(key: "content") var content: String
    @Field(key: "creation_date") var creationDate: Date
    @Field(key: "latitude") var latitude: Double
    @Field(key: "longitude") var longitude: Double
    
    @Parent(key: "id_user") var user: User
    @Parent(key: "id_danger_category") var dangerCategory: DangerCategory
    
    @Children(for: \.$dangerPost) var dangerComments: [DangerComment]
    @Children(for: \.$dangerPost) var dangerPostReports: [DangerPostReport]

    @Siblings(through: DangerPostFav.self, from: \.$dangerPost, to: \.$user) var usersFaved: [User]
    @Siblings(through: DangerPostLike.self, from: \.$dangerPost, to: \.$user) var usersLiked: [User]

    init() { }
}
