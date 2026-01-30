import Fluent
import struct Foundation.UUID

final class PlaceCategorization: Model, @unchecked Sendable {
    static let schema = "place_categorization"
    
    @ID(key: .id) var id: UUID?
        
    @Parent(key: "id_place") var place: Place
    @Parent(key: "id_place_category") var placeCategory: PlaceCategory

    init() { }
}
