//
//  PatchPlaceDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 25/03/2026.
//

import Vapor

struct PatchPlaceDTO: Content {
  var name: String?
  var categoriesIds: [UUID]?
  var address: String??
  var zipCode: String??
  var city: String??
  var country: String??
  var phoneNumber: String??
  var email: String??
  var website: String??
  var otherDetails: String??
  var latitude: Double?
  var longitude: Double?
}

// Make ?? variables nullable in the patch
extension PatchPlaceDTO {
  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    name = try container.decodeIfPresent(String.self, forKey: .name)
    categoriesIds = try container.decodeIfPresent([UUID].self, forKey: .categoriesIds)
    latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
    longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
    address = try container.decodeNullablePatchVariable(String.self, forKey: .address)
    zipCode = try container.decodeNullablePatchVariable(String.self, forKey: .zipCode)
    city = try container.decodeNullablePatchVariable(String.self, forKey: .city)
    country = try container.decodeNullablePatchVariable(String.self, forKey: .country)
    phoneNumber = try container.decodeNullablePatchVariable(String.self, forKey: .phoneNumber)
    email = try container.decodeNullablePatchVariable(String.self, forKey: .email)
    website = try container.decodeNullablePatchVariable(String.self, forKey: .website)
    otherDetails = try container.decodeNullablePatchVariable(String.self, forKey: .otherDetails)
  }
}

extension PatchPlaceDTO: Validatable {
  static func validations(_ validations: inout Validations) {
    validations.add("name", as: String.self, is: .count(1...50), required: false)
    validations.add("categoriesIds", as: [UUID].self, is: .count(1...), required: false)
    validations.add("address", as: String.self, is: .count(1...100), required: false)
    validations.add("zipCode", as: String.self, is: .count(1...6) && .alphanumeric, required: false)
    validations.add("city", as: String.self, is: .count(1...50), required: false)
    validations.add("country", as: String.self, is: .count(1...50), required: false)
    validations.add("phoneNumber", as: String.self, is: .internationalPhoneNumber, required: false)
    validations.add("email", as: String.self, is: .count(1...100) && .internationalEmail, required: false)
    validations.add("website", as: String.self, is: .count(1...100) && .url, required: false)
    validations.add("otherDetails", as: String.self, is: .count(1...10000), required: false)
    validations.add("latitude", as: Double.self, is: .range(-90.0...90.0), required: false)
    validations.add("longitude", as: Double.self, is: .range(-180.0...180.0), required: false)
  }
}
