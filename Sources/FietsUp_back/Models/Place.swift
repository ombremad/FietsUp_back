import Fluent
import struct Foundation.UUID

final class Place: Model, @unchecked Sendable {
    static let schema = "places"
    
    @ID(key: .id) var id: UUID?
    
    @Field(key: "name") var name: String
    @Field(key: "address") var address: String?
    @Field(key: "zip_code") var zipCode: String?
    @Field(key: "city") var city: String?
    @Field(key: "country") var country: String?
    @Field(key: "phone_number") var phoneNumber: String?
    @Field(key: "email") var email: String?
    @Field(key: "website") var website: String?
    @Field(key: "other_details") var otherDetails: String?
    @Field(key: "latitude") var latitude: Double
    @Field(key: "longitude") var longitude: Double
    @Field(key: "creation_date") var creationDate: Date
    @Field(key: "last_update_date") var lastUpdateDate: Date
    
    @Children(for: \.$place) var ratings: [Rating]
    
    @Siblings(through: PlaceCategorization.self, from: \.$place, to: \.$placeCategory) var categories: [PlaceCategory]

    init() { }
}
