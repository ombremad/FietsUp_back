@testable import FietsUp_back
import Fluent
import VaporTesting
import Testing

extension DatabaseTests {
  @Suite("Cycle Type Controller Tests with DB", .serialized)
  struct CycleTypeControllerTests {
    // MARK: - GET /cycles/types

    @Test("Listing cycle types requires a token")
    func getAllWithoutToken() async throws {
      try await withAppIncludingDB { app in
        try await app.testing().test(.GET, "cycles/types") { res async in
          #expect(res.status == .unauthorized)
        }
      }
    }

    @Test("Listing cycle types as a regular user returns them sorted by file link")
    func getAll() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        try await makeCycleType(name: "One", fileLink: "https://example.com/c.png", on: app.db)
        try await makeCycleType(name: "Two", fileLink: "https://example.com/a.png", on: app.db)
        try await makeCycleType(name: "Three", fileLink: "https://example.com/b.png", on: app.db)

        try await app.testing().test(
          .GET, "cycles/types",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let dtos = try res.content.decode([GetCycleTypeDTO].self)
            #expect(dtos.map(\.name) == ["Two", "Three", "One"])
          })
      }
    }

    // MARK: - POST /cycles/types

    @Test("Creating a cycle type as an admin trims and saves it")
    func createAsAdmin() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)

        try await app.testing().test(
          .POST, "cycles/types",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(CreateCycleTypeDTO(name: "  Gazelle  ", fileLink: "https://example.com/g.png"))
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let dto = try res.content.decode(GetCycleTypeDTO.self)
            #expect(dto.name == "Gazelle")
            #expect(dto.fileLink == "https://example.com/g.png")
            #expect(try await CycleType.query(on: app.db).count() == 1)
          })
      }
    }

    @Test("Creating a cycle type as a moderator is forbidden")
    func createAsModerator() async throws {
      try await withAppIncludingDB { app in
        let moderator = try await makeUser(adminRights: 1, on: app.db)

        try await app.testing().test(
          .POST, "cycles/types",
          beforeRequest: { req in
            try authorize(&req, as: moderator)
            try req.content.encode(CreateCycleTypeDTO(name: "Gazelle", fileLink: "https://example.com/g.png"))
          },
          afterResponse: { res async throws in
            #expect(res.status == .forbidden)
            #expect(try await CycleType.query(on: app.db).count() == 0)
          })
      }
    }

    @Test(
      "Creating a cycle type with an invalid file link fails validation",
      arguments: ["not a url", "", "https://example.com/" + String(repeating: "a", count: 100)])
    func createInvalidFileLink(fileLink: String) async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)

        try await app.testing().test(
          .POST, "cycles/types",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(CreateCycleTypeDTO(name: "Gazelle", fileLink: fileLink))
          },
          afterResponse: { res async throws in
            #expect(res.status == .badRequest)
            #expect(try await CycleType.query(on: app.db).count() == 0)
          })
      }
    }

    @Test("Creating a cycle type with a name already in use returns 409")
    func createDuplicateName() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)
        try await makeCycleType(name: "Gazelle", on: app.db)

        try await app.testing().test(
          .POST, "cycles/types",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(CreateCycleTypeDTO(name: "Gazelle", fileLink: "https://example.com/other.png"))
          },
          afterResponse: { res async in
            #expect(res.status == .conflict)
          })
      }
    }

    // MARK: - PATCH /cycles/types/:id

    @Test("Patching a cycle type's name leaves its file link untouched")
    func patchName() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)
        let model = try await makeCycleType(name: "Gazelle", fileLink: "https://example.com/g.png", on: app.db)

        try await app.testing().test(
          .PATCH, "cycles/types/\(model.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(PatchCycleTypeDTO(name: " Batavus "))
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let stored = try #require(try await CycleType.find(model.id, on: app.db))
            #expect(stored.name == "Batavus")
            #expect(stored.fileLink == "https://example.com/g.png")
          })
      }
    }

    @Test("Patching a cycle type with an invalid file link fails validation")
    func patchInvalidFileLink() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)
        let model = try await makeCycleType(fileLink: "https://example.com/g.png", on: app.db)

        try await app.testing().test(
          .PATCH, "cycles/types/\(model.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(PatchCycleTypeDTO(fileLink: "not a url"))
          },
          afterResponse: { res async throws in
            #expect(res.status == .badRequest)
            #expect(try await CycleType.find(model.id, on: app.db)?.fileLink == "https://example.com/g.png")
          })
      }
    }

    @Test("Patching a cycle type as a moderator is forbidden")
    func patchAsModerator() async throws {
      try await withAppIncludingDB { app in
        let moderator = try await makeUser(adminRights: 1, on: app.db)
        let model = try await makeCycleType(name: "Gazelle", on: app.db)

        try await app.testing().test(
          .PATCH, "cycles/types/\(model.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: moderator)
            try req.content.encode(PatchCycleTypeDTO(name: "Batavus"))
          },
          afterResponse: { res async throws in
            #expect(res.status == .forbidden)
            #expect(try await CycleType.find(model.id, on: app.db)?.name == "Gazelle")
          })
      }
    }

    @Test("Patching an unknown cycle type returns 404")
    func patchUnknownID() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)

        try await app.testing().test(
          .PATCH, "cycles/types/\(UUID())",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(PatchCycleTypeDTO(name: "Batavus"))
          },
          afterResponse: { res async in
            #expect(res.status == .notFound)
          })
      }
    }

    @Test("Patching a cycle type to a name already in use returns 409")
    func patchDuplicateName() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)
        try await makeCycleType(name: "Gazelle", on: app.db)
        let model = try await makeCycleType(name: "Batavus", fileLink: "https://example.com/b.png", on: app.db)

        try await app.testing().test(
          .PATCH, "cycles/types/\(model.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(PatchCycleTypeDTO(name: "Gazelle"))
          },
          afterResponse: { res async in
            #expect(res.status == .conflict)
          })
      }
    }
  }
}
