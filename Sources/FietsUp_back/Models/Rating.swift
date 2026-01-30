import Fluent
import struct Foundation.UUID

final class Rating: Model, @unchecked Sendable {
    static let schema = "ratings"
    
    @ID(key: .id) var id: UUID?
    
    @Field(key: "note") var note: Int
    
    @Parent(key: "id_user") var user: User
    @Parent(key: "id_place") var place: Place

    init() { }
}
