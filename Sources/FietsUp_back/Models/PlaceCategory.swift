import Fluent
import struct Foundation.UUID

final class PlaceCategory: Model, @unchecked Sendable {
    static let schema = "place_categories"
    
    @ID(key: .id) var id: UUID?
    
    @Field(key: "name") var name: String
    @Field(key: "icon_name") var iconName: String
    
    @Siblings(through: PlaceCategorization.self, from: \.$placeCategory, to: \.$place) var places: [Place]
    
    init() { }
}
