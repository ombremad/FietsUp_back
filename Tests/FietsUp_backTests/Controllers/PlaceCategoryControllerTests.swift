@testable import FietsUp_back
import Fluent
import VaporTesting
import Testing

extension DatabaseTests {
  @Suite("Place Category Controller Tests with DB", .serialized)
  struct PlaceCategoryControllerTests {
    // MARK: - GET /places/categories

    @Test("Listing place categories requires a token")
    func getAllWithoutToken() async throws {
      try await withAppIncludingDB { app in
        try await app.testing().test(.GET, "places/categories") { res async in
          #expect(res.status == .unauthorized)
        }
      }
    }

    @Test("Listing place categories as a regular user returns them sorted by name")
    func getAll() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        for name in ["Charlie", "Alpha", "Bravo"] {
          try await makePlaceCategory(name: name, on: app.db)
        }

        try await app.testing().test(
          .GET, "places/categories",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let dtos = try res.content.decode([GetPlaceCategoryDTO].self)
            #expect(dtos.map(\.name) == ["Alpha", "Bravo", "Charlie"])
          })
      }
    }

    // MARK: - POST /places/categories

    @Test("Creating a place category as an admin trims and saves it")
    func createAsAdmin() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)

        try await app.testing().test(
          .POST, "places/categories",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(CreatePlaceCategoryDTO(name: "  Alpha  ", iconName: "alpha"))
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let dto = try res.content.decode(GetPlaceCategoryDTO.self)
            #expect(dto.name == "Alpha")
            #expect(dto.iconName == "alpha")
            #expect(try await PlaceCategory.query(on: app.db).count() == 1)
          })
      }
    }

    @Test("Creating a place category as a moderator is forbidden")
    func createAsModerator() async throws {
      try await withAppIncludingDB { app in
        let moderator = try await makeUser(adminRights: 1, on: app.db)

        try await app.testing().test(
          .POST, "places/categories",
          beforeRequest: { req in
            try authorize(&req, as: moderator)
            try req.content.encode(CreatePlaceCategoryDTO(name: "Alpha", iconName: "alpha"))
          },
          afterResponse: { res async throws in
            #expect(res.status == .forbidden)
            #expect(try await PlaceCategory.query(on: app.db).count() == 0)
          })
      }
    }

    @Test(
      "Creating a place category with invalid fields fails validation",
      arguments: [("", "alpha"), (String(repeating: "a", count: 51), "alpha"), ("Alpha", "icône"), ("Alpha", "")])
    func createInvalid(name: String, iconName: String) async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)

        try await app.testing().test(
          .POST, "places/categories",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(CreatePlaceCategoryDTO(name: name, iconName: iconName))
          },
          afterResponse: { res async throws in
            #expect(res.status == .badRequest)
            #expect(try await PlaceCategory.query(on: app.db).count() == 0)
          })
      }
    }

    @Test("Creating a place category with a name already in use returns 409")
    func createDuplicateName() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)
        try await makePlaceCategory(name: "Alpha", on: app.db)

        try await app.testing().test(
          .POST, "places/categories",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(CreatePlaceCategoryDTO(name: "Alpha", iconName: "other"))
          },
          afterResponse: { res async in
            #expect(res.status == .conflict)
          })
      }
    }

    // MARK: - PATCH /places/categories/:id

    @Test("Patching a place category's name leaves its icon untouched")
    func patchName() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)
        let category = try await makePlaceCategory(name: "Alpha", iconName: "alpha", on: app.db)

        try await app.testing().test(
          .PATCH, "places/categories/\(category.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(PatchPlaceCategoryDTO(name: " Omega "))
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let stored = try #require(try await PlaceCategory.find(category.id, on: app.db))
            #expect(stored.name == "Omega")
            #expect(stored.iconName == "alpha")
          })
      }
    }

    @Test("Patching a place category with a non-ASCII icon fails validation")
    func patchInvalidIcon() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)
        let category = try await makePlaceCategory(iconName: "alpha", on: app.db)

        try await app.testing().test(
          .PATCH, "places/categories/\(category.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(PatchPlaceCategoryDTO(iconName: "icône"))
          },
          afterResponse: { res async throws in
            #expect(res.status == .badRequest)
            #expect(try await PlaceCategory.find(category.id, on: app.db)?.iconName == "alpha")
          })
      }
    }

    @Test("Patching a place category as a moderator is forbidden")
    func patchAsModerator() async throws {
      try await withAppIncludingDB { app in
        let moderator = try await makeUser(adminRights: 1, on: app.db)
        let category = try await makePlaceCategory(name: "Alpha", on: app.db)

        try await app.testing().test(
          .PATCH, "places/categories/\(category.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: moderator)
            try req.content.encode(PatchPlaceCategoryDTO(name: "Omega"))
          },
          afterResponse: { res async throws in
            #expect(res.status == .forbidden)
            #expect(try await PlaceCategory.find(category.id, on: app.db)?.name == "Alpha")
          })
      }
    }

    @Test("Patching an unknown place category returns 404")
    func patchUnknownID() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)

        try await app.testing().test(
          .PATCH, "places/categories/\(UUID())",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(PatchPlaceCategoryDTO(name: "Omega"))
          },
          afterResponse: { res async in
            #expect(res.status == .notFound)
          })
      }
    }

    @Test("Patching a place category to a name already in use returns 409")
    func patchDuplicateName() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)
        try await makePlaceCategory(name: "Alpha", on: app.db)
        let category = try await makePlaceCategory(name: "Bravo", on: app.db)

        try await app.testing().test(
          .PATCH, "places/categories/\(category.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(PatchPlaceCategoryDTO(name: "Alpha"))
          },
          afterResponse: { res async in
            #expect(res.status == .conflict)
          })
      }
    }

    // MARK: - DELETE /places/categories/:id

    @Test("Deleting a place category removes it from places but keeps the places")
    func deleteAsAdmin() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)
        let deleted = try await makePlaceCategory(name: "Alpha", on: app.db)
        let kept = try await makePlaceCategory(name: "Bravo", on: app.db)
        let place = try await makePlace(categories: [deleted, kept], on: app.db)

        try await app.testing().test(
          .DELETE, "places/categories/\(deleted.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: admin)
          },
          afterResponse: { res async throws in
            #expect(res.status == .noContent)
            #expect(try await PlaceCategory.find(deleted.id, on: app.db) == nil)
            let stored = try #require(try await Place.find(place.id, on: app.db))
            let categories = try await stored.$categories.get(on: app.db)
            #expect(categories.map(\.id) == [kept.id])
          })
      }
    }

    @Test("Deleting a place category as a moderator is forbidden")
    func deleteAsModerator() async throws {
      try await withAppIncludingDB { app in
        let moderator = try await makeUser(adminRights: 1, on: app.db)
        let category = try await makePlaceCategory(on: app.db)

        try await app.testing().test(
          .DELETE, "places/categories/\(category.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: moderator)
          },
          afterResponse: { res async throws in
            #expect(res.status == .forbidden)
            #expect(try await PlaceCategory.find(category.id, on: app.db) != nil)
          })
      }
    }

    @Test("Deleting an unknown place category returns 404")
    func deleteUnknownID() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)

        try await app.testing().test(
          .DELETE, "places/categories/\(UUID())",
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
