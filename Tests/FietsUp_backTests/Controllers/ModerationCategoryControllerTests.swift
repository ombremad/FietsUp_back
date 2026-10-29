@testable import FietsUp_back
import Fluent
import VaporTesting
import Testing

extension DatabaseTests {
  @Suite("Moderation Category Tests with DB", .serialized)
  struct ModerationCategoryControllerTests {
    @Test("Listing categories requires a token")
    func getAllWithoutToken() async throws {
      try await withAppIncludingDB { app in
        try await app.testing().test(.GET, "moderation/categories") { res async in
          #expect(res.status == .unauthorized)
        }
      }
    }

    @Test("Listing categories as a regular user returns them sorted by name")
    func getAllSorted() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(adminRights: 0, on: app.db)
        let categories = ["Spam", "Harcèlement", "Autre"].map { name in
          let category = ModerationCategory()
          category.name = name
          return category
        }
        try await categories.create(on: app.db)

        try await app.testing().test(
          .GET, "moderation/categories",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let dtos = try res.content.decode([GetModerationCategoryDTO].self)
            #expect(dtos.map(\.name) == ["Autre", "Harcèlement", "Spam"])
          })
      }
    }

    @Test("Creating a category as an admin trims and saves it")
    func createAsAdmin() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)

        try await app.testing().test(
          .POST, "moderation/categories",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(CreateModerationCategoryDTO(name: "  Spam  "))
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let dto = try res.content.decode(GetModerationCategoryDTO.self)
            #expect(dto.name == "Spam")
            let models = try await ModerationCategory.query(on: app.db).all()
            #expect(models.map(\.name) == ["Spam"])
          })
      }
    }

    @Test("Creating a category as a moderator is forbidden")
    func createAsModerator() async throws {
      try await withAppIncludingDB { app in
        let moderator = try await makeUser(adminRights: 1, on: app.db)

        try await app.testing().test(
          .POST, "moderation/categories",
          beforeRequest: { req in
            try authorize(&req, as: moderator)
            try req.content.encode(CreateModerationCategoryDTO(name: "Spam"))
          },
          afterResponse: { res async throws in
            #expect(res.status == .forbidden)
            let count = try await ModerationCategory.query(on: app.db).count()
            #expect(count == 0)
          })
      }
    }

    @Test("Creating a category with an empty name fails validation")
    func createWithEmptyName() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)

        try await app.testing().test(
          .POST, "moderation/categories",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(CreateModerationCategoryDTO(name: ""))
          },
          afterResponse: { res async throws in
            #expect(res.status == .badRequest)
            let count = try await ModerationCategory.query(on: app.db).count()
            #expect(count == 0)
          })
      }
    }

    @Test("Patching a category as an admin updates its name")
    func patchAsAdmin() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)
        let category = ModerationCategory()
        category.name = "Spam"
        try await category.save(on: app.db)

        try await app.testing().test(
          .PATCH, "moderation/categories/\(category.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(PatchModerationCategoryDTO(name: "Publicité"))
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let model = try await ModerationCategory.find(category.id, on: app.db)
            #expect(model?.name == "Publicité")
          })
      }
    }

    @Test("Patching an unknown category returns 404")
    func patchUnknownID() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)

        try await app.testing().test(
          .PATCH, "moderation/categories/\(UUID())",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(PatchModerationCategoryDTO(name: "Publicité"))
          },
          afterResponse: { res async in
            #expect(res.status == .notFound)
          })
      }
    }

    @Test("Creating a category with a name already in use returns 409")
    func createDuplicateName() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)
        try await makeModerationCategory(name: "Spam", on: app.db)

        try await app.testing().test(
          .POST, "moderation/categories",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(CreateModerationCategoryDTO(name: "Spam"))
          },
          afterResponse: { res async in
            #expect(res.status == .conflict)
          })
      }
    }

    @Test("Patching a category to a name already in use returns 409")
    func patchDuplicateName() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)
        try await makeModerationCategory(name: "Spam", on: app.db)
        let category = try await makeModerationCategory(name: "Other", on: app.db)

        try await app.testing().test(
          .PATCH, "moderation/categories/\(category.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(PatchModerationCategoryDTO(name: "Spam"))
          },
          afterResponse: { res async in
            #expect(res.status == .conflict)
          })
      }
    }
  }
}
