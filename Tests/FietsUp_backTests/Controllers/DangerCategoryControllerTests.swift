@testable import FietsUp_back
import Fluent
import VaporTesting
import Testing

extension DatabaseTests {
  @Suite("Danger Category Controller Tests with DB", .serialized)
  struct DangerCategoryControllerTests {
    // MARK: - GET /dangers/categories

    @Test("Listing danger categories requires a token")
    func getAllWithoutToken() async throws {
      try await withAppIncludingDB { app in
        try await app.testing().test(.GET, "dangers/categories") { res async in
          #expect(res.status == .unauthorized)
        }
      }
    }

    @Test("Listing danger categories as a regular user returns them sorted by name")
    func getAll() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        for name in ["Charlie", "Alpha", "Bravo"] {
          try await makeDangerCategory(name: name, on: app.db)
        }

        try await app.testing().test(
          .GET, "dangers/categories",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let dtos = try res.content.decode([GetDangerCategoryDTO].self)
            #expect(dtos.map(\.name) == ["Alpha", "Bravo", "Charlie"])
          })
      }
    }

    // MARK: - POST /dangers/categories

    @Test("Creating a danger category as an admin trims and saves it")
    func createAsAdmin() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)

        try await app.testing().test(
          .POST, "dangers/categories",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(CreateDangerCategoryDTO(name: "  Alpha  ", iconName: "alpha"))
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let dto = try res.content.decode(GetDangerCategoryDTO.self)
            #expect(dto.name == "Alpha")
            #expect(dto.iconName == "alpha")
            #expect(try await DangerCategory.query(on: app.db).count() == 1)
          })
      }
    }

    @Test("Creating a danger category as a moderator is forbidden")
    func createAsModerator() async throws {
      try await withAppIncludingDB { app in
        let moderator = try await makeUser(adminRights: 1, on: app.db)

        try await app.testing().test(
          .POST, "dangers/categories",
          beforeRequest: { req in
            try authorize(&req, as: moderator)
            try req.content.encode(CreateDangerCategoryDTO(name: "Alpha", iconName: "alpha"))
          },
          afterResponse: { res async throws in
            #expect(res.status == .forbidden)
            #expect(try await DangerCategory.query(on: app.db).count() == 0)
          })
      }
    }

    @Test(
      "Creating a danger category with invalid fields fails validation",
      arguments: [("", "alpha"), (String(repeating: "a", count: 51), "alpha"), ("Alpha", "icône"), ("Alpha", "")])
    func createInvalid(name: String, iconName: String) async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)

        try await app.testing().test(
          .POST, "dangers/categories",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(CreateDangerCategoryDTO(name: name, iconName: iconName))
          },
          afterResponse: { res async throws in
            #expect(res.status == .badRequest)
            #expect(try await DangerCategory.query(on: app.db).count() == 0)
          })
      }
    }

    @Test("Creating a danger category with a name already in use returns 409")
    func createDuplicateName() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)
        try await makeDangerCategory(name: "Alpha", on: app.db)

        try await app.testing().test(
          .POST, "dangers/categories",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(CreateDangerCategoryDTO(name: "Alpha", iconName: "other"))
          },
          afterResponse: { res async in
            #expect(res.status == .conflict)
          })
      }
    }

    // MARK: - PATCH /dangers/categories/:id

    @Test("Patching a danger category's name leaves its icon untouched")
    func patchName() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)
        let category = try await makeDangerCategory(name: "Alpha", iconName: "alpha", on: app.db)

        try await app.testing().test(
          .PATCH, "dangers/categories/\(category.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(PatchDangerCategoryDTO(name: " Omega "))
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let stored = try #require(try await DangerCategory.find(category.id, on: app.db))
            #expect(stored.name == "Omega")
            #expect(stored.iconName == "alpha")
          })
      }
    }

    @Test("Patching a danger category with a non-ASCII icon fails validation")
    func patchInvalidIcon() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)
        let category = try await makeDangerCategory(iconName: "alpha", on: app.db)

        try await app.testing().test(
          .PATCH, "dangers/categories/\(category.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(PatchDangerCategoryDTO(iconName: "icône"))
          },
          afterResponse: { res async throws in
            #expect(res.status == .badRequest)
            #expect(try await DangerCategory.find(category.id, on: app.db)?.iconName == "alpha")
          })
      }
    }

    @Test("Patching a danger category as a moderator is forbidden")
    func patchAsModerator() async throws {
      try await withAppIncludingDB { app in
        let moderator = try await makeUser(adminRights: 1, on: app.db)
        let category = try await makeDangerCategory(name: "Alpha", on: app.db)

        try await app.testing().test(
          .PATCH, "dangers/categories/\(category.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: moderator)
            try req.content.encode(PatchDangerCategoryDTO(name: "Omega"))
          },
          afterResponse: { res async throws in
            #expect(res.status == .forbidden)
            #expect(try await DangerCategory.find(category.id, on: app.db)?.name == "Alpha")
          })
      }
    }

    @Test("Patching an unknown danger category returns 404")
    func patchUnknownID() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)

        try await app.testing().test(
          .PATCH, "dangers/categories/\(UUID())",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(PatchDangerCategoryDTO(name: "Omega"))
          },
          afterResponse: { res async in
            #expect(res.status == .notFound)
          })
      }
    }

    @Test("Patching a danger category to a name already in use returns 409")
    func patchDuplicateName() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)
        try await makeDangerCategory(name: "Alpha", on: app.db)
        let category = try await makeDangerCategory(name: "Bravo", on: app.db)

        try await app.testing().test(
          .PATCH, "dangers/categories/\(category.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(PatchDangerCategoryDTO(name: "Alpha"))
          },
          afterResponse: { res async in
            #expect(res.status == .conflict)
          })
      }
    }
  }
}
