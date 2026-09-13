//
//  GetPlaceDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 25/03/2026.
//

import Vapor

struct GetPlaceDTO: Content {
  var id: UUID
  var name: String
  var categories: [PlaceCategory]
  var address: String?
  var zipCode: String?
  var city: String?
  var country: String?
  var phoneNumber: String?
  var email: String?
  var website: String?
  var otherDetails: String?
  var latitude: Double
  var longitude: Double
  var averageRating: Double?
  var creationDate: Date?
  var lastUpdateDate: Date?
}

extension GetPlaceDTO {
  init(from model: Place) throws {
    guard let id = model.id else { throw Abort(.internalServerError) }
    
    let averageRating: Double?
    if model.$ratings.value != nil {
      let ratings = model.ratings
      if ratings.isEmpty {
        averageRating = nil
      } else {
        let sum = ratings.reduce(0) { $0 + $1.note }
        let rawAverage = Double(sum) / Double(ratings.count)
        averageRating = (rawAverage * 2).rounded() / 2
      }
    } else {
      averageRating = nil
    }
    
    self.init(
      id: id,
      name: model.name,
      categories: model.categories,
      address: model.address,
      zipCode: model.zipCode,
      city: model.city,
      country: model.country,
      phoneNumber: model.phoneNumber,
      email: model.email,
      website: model.website,
      otherDetails: model.otherDetails,
      latitude: model.latitude,
      longitude: model.longitude,
      averageRating: averageRating,
      creationDate: model.creationDate,
      lastUpdateDate: model.lastUpdateDate
    )
  }
}

