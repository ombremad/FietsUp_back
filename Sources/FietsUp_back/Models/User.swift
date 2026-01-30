import Fluent
import struct Foundation.UUID

final class User: Model, @unchecked Sendable {
    static let schema = "users"
    
    @ID(key: .id) var id: UUID?
    
    @Field(key: "first_name") var firstName: String
    @Field(key: "last_name") var lastName: String
    @Field(key: "nickname") var nickname: String
    @Field(key: "email") var email: String
    @Field(key: "password") var password: String
    @Field(key: "creation_date") var creationDate: Date
    @Field(key: "ban_end_date") var banEndDate: Date?
    @Field(key: "admin_rights") var adminRights: Int
    @Field(key: "bio") var bio: String?
    @Field(key: "streak") var streak: Int
    
    @Parent(key: "id_cycle_type") var cycleType: CycleType
    @Parent(key: "id_cycle_color") var cycleColor: CycleColor
    @Parent(key: "id_cycle_decoration") var cycleDecoration: CycleDecoration
    
    @Children(for: \.$user) var activities: [Activity]
    @Children(for: \.$user) var dangerComments: [DangerComment]
    @Children(for: \.$user) var dangerCommentReports: [DangerCommentReport]
    @Children(for: \.$user) var dangerPosts: [DangerPost]
    @Children(for: \.$user) var dangerPostReports: [DangerPostReport]
    @Children(for: \.$user) var forumComments: [ForumComment]
    @Children(for: \.$user) var forumCommentReports: [ForumCommentReport]
    @Children(for: \.$user) var forumPosts: [ForumPost]
    @Children(for: \.$user) var forumPostReports: [ForumPostReport]
    @Children(for: \.$user) var ratings: [Rating]
    
    @Siblings(through: CycleColorOwnership.self, from: \.$user, to: \.$cycleColor) var cycleColorsOwned: [CycleColor]
    @Siblings(through: CycleDecorationOwnership.self, from: \.$user, to: \.$cycleDecoration) var cycleDecorationsOwned: [CycleDecoration]
    @Siblings(through: CycleTypeOwnership.self, from: \.$user, to: \.$cycleType) var cycleTypeOwned: [CycleType]
    @Siblings(through: DangerCommentFav.self, from: \.$user, to: \.$dangerComment) var dangerCommentFavs: [DangerComment]
    @Siblings(through: DangerCommentLike.self, from: \.$user, to: \.$dangerComment) var dangerCommentLikes: [DangerComment]
    @Siblings(through: DangerPostFav.self, from: \.$user, to: \.$dangerPost) var dangerPostFavs: [DangerPost]
    @Siblings(through: DangerPostLike.self, from: \.$user, to: \.$dangerPost) var dangerPostLikes: [DangerPost]
    @Siblings(through: ForumCommentFav.self, from: \.$user, to: \.$forumComment) var forumCommentFavs: [ForumComment]
    @Siblings(through: ForumCommentLike.self, from: \.$user, to: \.$forumComment) var forumCommentLikes: [ForumComment]
    @Siblings(through: ForumPostFav.self, from: \.$user, to: \.$forumPost) var forumPostFavs: [ForumPost]
    @Siblings(through: ForumPostLike.self, from: \.$user, to: \.$forumPost) var forumPostLikes: [ForumPost]

    init() { }
}
