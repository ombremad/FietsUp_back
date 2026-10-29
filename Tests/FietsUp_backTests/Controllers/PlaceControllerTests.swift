@testable import FietsUp_back
import Fluent
import VaporTesting
import Testing

extension DatabaseTests {
  @Suite("Place Controller Tests with DB", .serialized)
  struct PlaceControllerTests {
    // Around Paris: 0.09° of latitude ≈ 10 km, 0.27° ≈ 30 km, 0.54° ≈ 60 km.
    private let latitude = 48.8566
    private let longitude = 2.3522

    private var nearQuery: String { "places/near?latitude=\(latitude)&longitude=\(longitude)" }

    private func dto(name: String = "Bike shop", categories: [PlaceCategory]) throws -> CreatePlaceDTO {
      CreatePlaceDTO(
        name: name, categoriesIds: try categories.map { try $0.requireID() },
        latitude: latitude, longitude: longitude)
    }

    // MARK: - POST /places

    @Test("Creating a place as an admin saves it with its categories, trimmed and normalized")
    func createAsAdmin() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)
        let category = try await makePlaceCategory(on: app.db)
        var body = try dto(name: "  Bike shop  ", categories: [category])
        body.email = "Shop@Example.COM"
        body.city = " Paris "

        try await app.testing().test(
          .POST, "places",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(body)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let place = try res.content.decode(GetPlaceWithRatingDTO.self)
            #expect(place.name == "Bike shop")
            #expect(place.email == "shop@example.com")
            #expect(place.city == "Paris")
            #expect(place.categories.map(\.id) == [category.id])
            #expect(place.averageRating == nil)
          })
      }
    }

    @Test("Creating a place as a moderator is forbidden")
    func createAsModerator() async throws {
      try await withAppIncludingDB { app in
        let moderator = try await makeUser(adminRights: 1, on: app.db)
        let body = try dto(categories: [try await makePlaceCategory(on: app.db)])

        try await app.testing().test(
          .POST, "places",
          beforeRequest: { req in
            try authorize(&req, as: moderator)
            try req.content.encode(body)
          },
          afterResponse: { res async throws in
            #expect(res.status == .forbidden)
            #expect(try await Place.query(on: app.db).count() == 0)
          })
      }
    }

    @Test("Creating a place without categories fails validation")
    func createWithoutCategories() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)

        try await app.testing().test(
          .POST, "places",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(try dto(categories: []))
          },
          afterResponse: { res async throws in
            #expect(res.status == .badRequest)
            #expect(try await Place.query(on: app.db).count() == 0)
          })
      }
    }

    @Test(
      "Creating a place with an invalid contact field fails validation",
      arguments: [
        (\CreatePlaceDTO.phoneNumber, "not a phone"),
        (\CreatePlaceDTO.email, "not-an-email"),
        (\CreatePlaceDTO.website, "not a url"),
        (\CreatePlaceDTO.zipCode, "75 001"),
      ])
    func createInvalidField(field: WritableKeyPath<CreatePlaceDTO, String?>, value: String) async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)
        var body = try dto(categories: [try await makePlaceCategory(on: app.db)])
        body[keyPath: field] = value

        try await app.testing().test(
          .POST, "places",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(body)
          },
          afterResponse: { res async throws in
            #expect(res.status == .badRequest)
            #expect(try await Place.query(on: app.db).count() == 0)
          })
      }
    }

    @Test("Creating a place with an unknown category returns 404")
    func createUnknownCategory() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)
        let body = CreatePlaceDTO(name: "Bike shop", categoriesIds: [UUID()], latitude: latitude, longitude: longitude)

        try await app.testing().test(
          .POST, "places",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(body)
          },
          afterResponse: { res async throws in
            #expect(res.status == .notFound)
            #expect(try await Place.query(on: app.db).count() == 0)
          })
      }
    }

    // MARK: - POST /places/batch

    @Test("Creating places in batch saves all of them")
    func createBatch() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)
        let category = try await makePlaceCategory(on: app.db)
        let body = [try dto(name: "One", categories: [category]), try dto(name: "Two", categories: [category])]

        try await app.testing().test(
          .POST, "places/batch",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(body)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            #expect(try res.content.decode([GetPlaceWithRatingDTO].self).map(\.name) == ["One", "Two"])
            #expect(try await Place.query(on: app.db).count() == 2)
          })
      }
    }

    @Test("Creating places in batch with one invalid place creates none")
    func createBatchWithInvalidPlace() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)
        let category = try await makePlaceCategory(on: app.db)
        let body = [try dto(name: "One", categories: [category]), try dto(name: "", categories: [category])]

        try await app.testing().test(
          .POST, "places/batch",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(body)
          },
          afterResponse: { res async throws in
            #expect(res.status == .badRequest)
            #expect(try await Place.query(on: app.db).count() == 0)
          })
      }
    }

    @Test("Creating places in batch with an unknown category returns 404")
    func createBatchUnknownCategory() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)
        let body = [CreatePlaceDTO(name: "One", categoriesIds: [UUID()], latitude: latitude, longitude: longitude)]

        try await app.testing().test(
          .POST, "places/batch",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(body)
          },
          afterResponse: { res async throws in
            #expect(res.status == .notFound)
            #expect(try await Place.query(on: app.db).count() == 0)
          })
      }
    }

    // MARK: - POST /places/:id/rating

    @Test("Rating a place requires a token")
    func rateWithoutToken() async throws {
      try await withAppIncludingDB { app in
        let place = try await makePlace(categories: [try await makePlaceCategory(on: app.db)], on: app.db)

        try await app.testing().test(
          .POST, "places/\(place.requireID())/rating",
          beforeRequest: { req in
            try req.content.encode(CreateOrPatchRatingDTO(note: 4))
          },
          afterResponse: { res async throws in
            #expect(res.status == .unauthorized)
            #expect(try await Rating.query(on: app.db).count() == 0)
          })
      }
    }

    @Test("Rating a place sets its average rating")
    func rate() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let place = try await makePlace(categories: [try await makePlaceCategory(on: app.db)], on: app.db)

        try await app.testing().test(
          .POST, "places/\(place.requireID())/rating",
          beforeRequest: { req in
            try authorize(&req, as: user)
            try req.content.encode(CreateOrPatchRatingDTO(note: 4))
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            #expect(try res.content.decode(GetPlaceWithRatingDTO.self).averageRating == 4)
          })
      }
    }

    @Test("Rating a place again replaces my previous rating")
    func rateTwice() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let place = try await makePlace(categories: [try await makePlaceCategory(on: app.db)], on: app.db)
        try await makeRating(note: 1, by: user, on: place, on: app.db)

        try await app.testing().test(
          .POST, "places/\(place.requireID())/rating",
          beforeRequest: { req in
            try authorize(&req, as: user)
            try req.content.encode(CreateOrPatchRatingDTO(note: 5))
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            #expect(try res.content.decode(GetPlaceWithRatingDTO.self).averageRating == 5)
            #expect(try await Rating.query(on: app.db).count() == 1)
          })
      }
    }

    @Test("A place's average rating is rounded to two decimals")
    func rateAverageRounding() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let place = try await makePlace(categories: [try await makePlaceCategory(on: app.db)], on: app.db)
        try await makeRating(note: 1, by: try await makeUser(on: app.db), on: place, on: app.db)
        try await makeRating(note: 2, by: try await makeUser(on: app.db), on: place, on: app.db)

        try await app.testing().test(
          .POST, "places/\(place.requireID())/rating",
          beforeRequest: { req in
            try authorize(&req, as: user)
            try req.content.encode(CreateOrPatchRatingDTO(note: 2))
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            #expect(try res.content.decode(GetPlaceWithRatingDTO.self).averageRating == 1.67)
          })
      }
    }

    @Test("Rating a place outside 1 to 5 fails validation", arguments: [0, 6])
    func rateOutOfRange(note: Int) async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let place = try await makePlace(categories: [try await makePlaceCategory(on: app.db)], on: app.db)

        try await app.testing().test(
          .POST, "places/\(place.requireID())/rating",
          beforeRequest: { req in
            try authorize(&req, as: user)
            try req.content.encode(CreateOrPatchRatingDTO(note: note))
          },
          afterResponse: { res async throws in
            #expect(res.status == .badRequest)
            #expect(try await Rating.query(on: app.db).count() == 0)
          })
      }
    }

    @Test("Rating an unknown place returns 404")
    func rateUnknownPlace() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)

        try await app.testing().test(
          .POST, "places/\(UUID())/rating",
          beforeRequest: { req in
            try authorize(&req, as: user)
            try req.content.encode(CreateOrPatchRatingDTO(note: 4))
          },
          afterResponse: { res async in
            #expect(res.status == .notFound)
          })
      }
    }

    // MARK: - GET /places/near

    @Test("Nearby places are those within 50 km, closest first")
    func getNearest() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let category = try await makePlaceCategory(on: app.db)
        try await makePlace(name: "30 km", latitude: latitude + 0.27, categories: [category], on: app.db)
        try await makePlace(name: "60 km", latitude: latitude + 0.54, categories: [category], on: app.db)
        try await makePlace(name: "10 km", latitude: latitude + 0.09, categories: [category], on: app.db)

        try await app.testing().test(
          .GET, nearQuery,
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            #expect(try res.content.decode([GetPlaceWithRatingDTO].self).map(\.name) == ["10 km", "30 km"])
          })
      }
    }

    @Test("Nearby places can be filtered by category")
    func getNearestByCategory() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let repair = try await makePlaceCategory(name: "Repair", on: app.db)
        let parking = try await makePlaceCategory(name: "Parking", on: app.db)
        try await makePlace(name: "Repair shop", categories: [repair], on: app.db)
        try await makePlace(name: "Parking lot", categories: [parking], on: app.db)

        try await app.testing().test(
          .GET, "\(nearQuery)&categoryID=\(repair.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            #expect(try res.content.decode([GetPlaceWithRatingDTO].self).map(\.name) == ["Repair shop"])
          })
      }
    }

    @Test(
      "Nearby places need valid coordinates",
      arguments: ["places/near", "places/near?latitude=91&longitude=2", "places/near?latitude=48&longitude=181"])
    func getNearestInvalidQuery(url: String) async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)

        try await app.testing().test(
          .GET, url,
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async in
            #expect(res.status == .badRequest)
          })
      }
    }

    // MARK: - GET /places

    @Test("Listing places as an admin pages them sorted by name")
    func getAll() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)
        let category = try await makePlaceCategory(on: app.db)
        for name in ["Charlie", "Alpha", "Bravo"] {
          try await makePlace(name: name, categories: [category], on: app.db)
        }

        try await app.testing().test(
          .GET, "places?page=1&per=2",
          beforeRequest: { req in
            try authorize(&req, as: admin)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let page = try res.content.decode(Page<GetPlaceWithRatingDTO>.self)
            #expect(page.items.map(\.name) == ["Alpha", "Bravo"])
            #expect(page.metadata.total == 3)
          })
      }
    }

    @Test("Listing places can be filtered by category")
    func getAllByCategory() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)
        let repair = try await makePlaceCategory(name: "Repair", on: app.db)
        let parking = try await makePlaceCategory(name: "Parking", on: app.db)
        try await makePlace(name: "Repair shop", categories: [repair], on: app.db)
        try await makePlace(name: "Parking lot", categories: [parking], on: app.db)

        try await app.testing().test(
          .GET, "places?categoryID=\(parking.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: admin)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            #expect(try res.content.decode(Page<GetPlaceWithRatingDTO>.self).items.map(\.name) == ["Parking lot"])
          })
      }
    }

    @Test("Listing places with more than 25 per page fails validation")
    func getAllPerTooLarge() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)

        try await app.testing().test(
          .GET, "places?per=26",
          beforeRequest: { req in
            try authorize(&req, as: admin)
          },
          afterResponse: { res async in
            #expect(res.status == .badRequest)
          })
      }
    }

    @Test("Listing places as a regular user is forbidden")
    func getAllAsRegularUser() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)

        try await app.testing().test(
          .GET, "places",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async in
            #expect(res.status == .forbidden)
          })
      }
    }

    // MARK: - PATCH /places/:id

    @Test("Patching a place with empty strings clears those fields, and emails are lowercased")
    func patchClearsFields() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)
        let place = try await makePlace(categories: [try await makePlaceCategory(on: app.db)], on: app.db)
        place.city = "Paris"
        place.website = "https://example.com"
        try await place.save(on: app.db)

        try await app.testing().test(
          .PATCH, "places/\(place.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(PatchPlaceDTO(city: "", email: "Shop@Example.COM", website: ""))
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let stored = try #require(try await Place.find(place.id, on: app.db))
            #expect(stored.city == nil)
            #expect(stored.website == nil)
            #expect(stored.email == "shop@example.com")
          })
      }
    }

    @Test("Patching a place's categories replaces the whole set")
    func patchCategories() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)
        let old = try await makePlaceCategory(name: "Old", on: app.db)
        let new = try await makePlaceCategory(name: "New", on: app.db)
        let place = try await makePlace(categories: [old], on: app.db)

        try await app.testing().test(
          .PATCH, "places/\(place.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(PatchPlaceDTO(categoriesIds: [new.requireID()]))
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            #expect(try res.content.decode(GetPlaceWithRatingDTO.self).categories.map(\.id) == [new.id])
          })
      }
    }

    @Test("Moving a place changes where it's found nearby")
    func patchLocation() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)
        let place = try await makePlace(name: "Moved", latitude: latitude + 2, categories: [try await makePlaceCategory(on: app.db)], on: app.db)

        try await app.testing().test(
          .PATCH, "places/\(place.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(PatchPlaceDTO(latitude: latitude, longitude: longitude))
          },
          afterResponse: { res async in
            #expect(res.status == .ok)
          })

        try await app.testing().test(
          .GET, nearQuery,
          beforeRequest: { req in
            try authorize(&req, as: admin)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            #expect(try res.content.decode([GetPlaceWithRatingDTO].self).map(\.name) == ["Moved"])
          })
      }
    }

    @Test("Patching a place with an unknown category returns 404")
    func patchUnknownCategory() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)
        let category = try await makePlaceCategory(on: app.db)
        let place = try await makePlace(categories: [category], on: app.db)

        try await app.testing().test(
          .PATCH, "places/\(place.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(PatchPlaceDTO(categoriesIds: [UUID()]))
          },
          afterResponse: { res async throws in
            #expect(res.status == .notFound)
            let stored = try #require(try await Place.find(place.id, on: app.db))
            #expect(try await stored.$categories.get(on: app.db).map(\.id) == [category.id])
          })
      }
    }

    @Test("Patching an unknown place returns 404")
    func patchUnknownID() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)

        try await app.testing().test(
          .PATCH, "places/\(UUID())",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(PatchPlaceDTO(name: "Renamed"))
          },
          afterResponse: { res async in
            #expect(res.status == .notFound)
          })
      }
    }

    // MARK: - DELETE /places/:id

    @Test("Deleting a place as an admin deletes its ratings too")
    func deleteAsAdmin() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)
        let place = try await makePlace(categories: [try await makePlaceCategory(on: app.db)], on: app.db)
        try await makeRating(note: 4, by: admin, on: place, on: app.db)

        try await app.testing().test(
          .DELETE, "places/\(place.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: admin)
          },
          afterResponse: { res async throws in
            #expect(res.status == .noContent)
            #expect(try await Place.find(place.id, on: app.db) == nil)
            #expect(try await Rating.query(on: app.db).count() == 0)
          })
      }
    }

    @Test("Deleting a place as a moderator is forbidden")
    func deleteAsModerator() async throws {
      try await withAppIncludingDB { app in
        let moderator = try await makeUser(adminRights: 1, on: app.db)
        let place = try await makePlace(categories: [try await makePlaceCategory(on: app.db)], on: app.db)

        try await app.testing().test(
          .DELETE, "places/\(place.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: moderator)
          },
          afterResponse: { res async throws in
            #expect(res.status == .forbidden)
            #expect(try await Place.find(place.id, on: app.db) != nil)
          })
      }
    }

    @Test("Deleting an unknown place returns 404")
    func deleteUnknownID() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)

        try await app.testing().test(
          .DELETE, "places/\(UUID())",
          beforeRequest: { req in
            try authorize(&req, as: admin)
          },
          afterResponse: { res async in
            #expect(res.status == .notFound)
          })
      }
    }
  }
}
