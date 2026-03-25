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
  @Timestamp(key: "creation_date", on: .create) var creationDate: Date?
  @Timestamp(key: "last_update_date", on: .update) var lastUpdateDate: Date?

  @Children(for: \.$place) var ratings: [Rating]

  @Siblings(through: PlaceCategorization.self, from: \.$place, to: \.$placeCategory) var categories:
    [PlaceCategory]

  init() {}
  
  convenience init(from dto: CreatePlaceDTO) {
    self.init()
    
    // user provided
    self.name = dto.name.trimmingCharacters(in: .whitespacesAndNewlines)
    self.address = dto.address?.trimmingCharacters(in: .whitespacesAndNewlines)
    self.zipCode = dto.zipCode?.trimmingCharacters(in: .whitespacesAndNewlines)
    self.city = dto.city?.trimmingCharacters(in: .whitespacesAndNewlines)
    self.country = dto.country?.trimmingCharacters(in: .whitespacesAndNewlines)
    self.phoneNumber = dto.phoneNumber?.trimmingCharacters(in: .whitespacesAndNewlines)
    self.email = dto.email?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    self.website = dto.website
    self.otherDetails = dto.otherDetails?.trimmingCharacters(in: .whitespacesAndNewlines)
    self.latitude = dto.latitude
    self.longitude = dto.longitude
  }
}

extension Place {
  func patch(with dto: PatchPlaceDTO) {
    if let name = dto.name {
      self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    if let address = dto.address {
      self.address = address?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    if let zipCode = dto.zipCode {
      self.zipCode = zipCode?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    if let city = dto.city {
      self.city = city?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    if let country = dto.country {
      self.country = country?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    if let phoneNumber = dto.phoneNumber {
      self.phoneNumber = phoneNumber?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    if let email = dto.email {
      self.email = email?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
    if let website = dto.website { self.website = website }
    if let otherDetails = dto.otherDetails {
      self.otherDetails = otherDetails?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    if let latitude = dto.latitude { self.latitude = latitude }
    if let longitude = dto.longitude { self.longitude = longitude }
  }
}
