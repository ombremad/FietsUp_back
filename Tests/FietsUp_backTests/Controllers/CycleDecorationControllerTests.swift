@testable import FietsUp_back
import Fluent
import VaporTesting
import Testing

extension DatabaseTests {
  @Suite("Cycle Decoration Controller Tests with DB", .serialized)
  struct CycleDecorationControllerTests {
    // MARK: - GET /cycles/decorations

    @Test("Listing cycle decorations requires a token")
    func getAllWithoutToken() async throws {
      try await withAppIncludingDB { app in
        try await app.testing().test(.GET, "cycles/decorations") { res async in
          #expect(res.status == .unauthorized)
        }
      }
    }

    @Test("Listing cycle decorations as a regular user returns them sorted by file link")
    func getAll() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        try await makeCycleDecoration(name: "One", fileLink: "https://example.com/c.png", on: app.db)
        try await makeCycleDecoration(name: "Two", fileLink: "https://example.com/a.png", on: app.db)
        try await makeCycleDecoration(name: "Three", fileLink: "https://example.com/b.png", on: app.db)

        try await app.testing().test(
          .GET, "cycles/decorations",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let dtos = try res.content.decode([GetCycleDecorationDTO].self)
            #expect(dtos.map(\.name) == ["Two", "Three", "One"])
          })
      }
    }

    // MARK: - POST /cycles/decorations

    @Test("Creating a cycle decoration as an admin trims and saves it")
    func createAsAdmin() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)

        try await app.testing().test(
          .POST, "cycles/decorations",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(CreateCycleDecorationDTO(name: "  Stars  ", fileLink: "https://example.com/g.png"))
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let dto = try res.content.decode(GetCycleDecorationDTO.self)
            #expect(dto.name == "Stars")
            #expect(dto.fileLink == "https://example.com/g.png")
            #expect(try await CycleDecoration.query(on: app.db).count() == 1)
          })
      }
    }

    @Test("Creating a cycle decoration as a moderator is forbidden")
    func createAsModerator() async throws {
      try await withAppIncludingDB { app in
        let moderator = try await makeUser(adminRights: 1, on: app.db)

        try await app.testing().test(
          .POST, "cycles/decorations",
          beforeRequest: { req in
            try authorize(&req, as: moderator)
            try req.content.encode(CreateCycleDecorationDTO(name: "Stars", fileLink: "https://example.com/g.png"))
          },
          afterResponse: { res async throws in
            #expect(res.status == .forbidden)
            #expect(try await CycleDecoration.query(on: app.db).count() == 0)
          })
      }
    }

    @Test(
      "Creating a cycle decoration with an invalid file link fails validation",
      arguments: ["not a url", "", "https://example.com/" + String(repeating: "a", count: 100)])
    func createInvalidFileLink(fileLink: String) async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)

        try await app.testing().test(
          .POST, "cycles/decorations",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(CreateCycleDecorationDTO(name: "Stars", fileLink: fileLink))
          },
          afterResponse: { res async throws in
            #expect(res.status == .badRequest)
            #expect(try await CycleDecoration.query(on: app.db).count() == 0)
          })
      }
    }

    @Test("Creating a cycle decoration with a name already in use returns 409")
    func createDuplicateName() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)
        try await makeCycleDecoration(name: "Stars", on: app.db)

        try await app.testing().test(
          .POST, "cycles/decorations",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(CreateCycleDecorationDTO(name: "Stars", fileLink: "https://example.com/other.png"))
          },
          afterResponse: { res async in
            #expect(res.status == .conflict)
          })
      }
    }

    // MARK: - PATCH /cycles/decorations/:id

    @Test("Patching a cycle decoration's name leaves its file link untouched")
    func patchName() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)
        let model = try await makeCycleDecoration(name: "Stars", fileLink: "https://example.com/g.png", on: app.db)

        try await app.testing().test(
          .PATCH, "cycles/decorations/\(model.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(PatchCycleDecorationDTO(name: " Stripes "))
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let stored = try #require(try await CycleDecoration.find(model.id, on: app.db))
            #expect(stored.name == "Stripes")
            #expect(stored.fileLink == "https://example.com/g.png")
          })
      }
    }

    @Test("Patching a cycle decoration with an invalid file link fails validation")
    func patchInvalidFileLink() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)
        let model = try await makeCycleDecoration(fileLink: "https://example.com/g.png", on: app.db)

        try await app.testing().test(
          .PATCH, "cycles/decorations/\(model.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(PatchCycleDecorationDTO(fileLink: "not a url"))
          },
          afterResponse: { res async throws in
            #expect(res.status == .badRequest)
            #expect(try await CycleDecoration.find(model.id, on: app.db)?.fileLink == "https://example.com/g.png")
          })
      }
    }

    @Test("Patching a cycle decoration as a moderator is forbidden")
    func patchAsModerator() async throws {
      try await withAppIncludingDB { app in
        let moderator = try await makeUser(adminRights: 1, on: app.db)
        let model = try await makeCycleDecoration(name: "Stars", on: app.db)

        try await app.testing().test(
          .PATCH, "cycles/decorations/\(model.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: moderator)
            try req.content.encode(PatchCycleDecorationDTO(name: "Stripes"))
          },
          afterResponse: { res async throws in
            #expect(res.status == .forbidden)
            #expect(try await CycleDecoration.find(model.id, on: app.db)?.name == "Stars")
          })
      }
    }

    @Test("Patching an unknown cycle decoration returns 404")
    func patchUnknownID() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)

        try await app.testing().test(
          .PATCH, "cycles/decorations/\(UUID())",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(PatchCycleDecorationDTO(name: "Stripes"))
          },
          afterResponse: { res async in
            #expect(res.status == .notFound)
          })
      }
    }

    @Test("Patching a cycle decoration to a name already in use returns 409")
    func patchDuplicateName() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)
        try await makeCycleDecoration(name: "Stars", on: app.db)
        let model = try await makeCycleDecoration(name: "Stripes", fileLink: "https://example.com/b.png", on: app.db)

        try await app.testing().test(
          .PATCH, "cycles/decorations/\(model.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(PatchCycleDecorationDTO(name: "Stars"))
          },
          afterResponse: { res async in
            #expect(res.status == .conflict)
          })
      }
    }
  }
}
