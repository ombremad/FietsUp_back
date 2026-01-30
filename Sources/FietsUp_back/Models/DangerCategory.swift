import Fluent
import struct Foundation.UUID

final class DangerCategory: Model, @unchecked Sendable {
    static let schema = "danger_categories"
    
    @ID(key: .id) var id: UUID?
    
    @Field(key: "name") var name: String
    @Field(key: "icon_name") var iconName: String
    
    @Children(for: \.$dangerCategory) var dangerPosts: [DangerPost]

    init() { }
}
