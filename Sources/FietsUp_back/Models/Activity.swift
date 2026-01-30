import Fluent
import struct Foundation.UUID

final class Activity: Model, @unchecked Sendable {
    static let schema = "activities"
    
    @ID(key: .id) var id: UUID?
    
    @Field(key: "start_date") var startDate: Date
    @Field(key: "end_date") var endDate: Date
    @Field(key: "length") var length: Int
    @Field(key: "distance") var distance: Int
    
    @Parent(key: "id_user") var user: User

    init() { }
}
