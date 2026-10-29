@testable import FietsUp_back
import Fluent
import VaporTesting
import Testing

extension DatabaseTests {
  @Suite("Cycle Color Controller Tests with DB", .serialized)
  struct CycleColorControllerTests {
    // MARK: - GET /cycles/colors

    @Test("Listing colors requires a token")
    func getAllWithoutToken() async throws {
      try await withAppIncludingDB { app in
        try await app.testing().test(.GET, "cycles/colors") { res async in
          #expect(res.status == .unauthorized)
        }
      }
    }

    @Test("Listing colors as a regular user returns them sorted by color, descending")
    func getAll() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        try await makeCycleColor(name: "Blue", color: "0000FF", on: app.db)
        try await makeCycleColor(name: "Red", color: "FF0000", on: app.db)
        try await makeCycleColor(name: "Green", color: "00FF00", on: app.db)

        try await app.testing().test(
          .GET, "cycles/colors",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let dtos = try res.content.decode([GetCycleColorDTO].self)
            #expect(dtos.map(\.color) == ["ff0000", "00ff00", "0000ff"])
          })
      }
    }

    // MARK: - POST /cycles/colors

    @Test("Creating a color as an admin trims the name, lowercases the color and saves it")
    func createAsAdmin() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)

        try await app.testing().test(
          .POST, "cycles/colors",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(CreateCycleColorDTO(name: "  Red  ", color: "FF0000"))
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let dto = try res.content.decode(GetCycleColorDTO.self)
            #expect(dto.name == "Red")
            #expect(dto.color == "ff0000")
            #expect(try await CycleColor.query(on: app.db).count() == 1)
          })
      }
    }

    @Test("Creating a color as a moderator is forbidden")
    func createAsModerator() async throws {
      try await withAppIncludingDB { app in
        let moderator = try await makeUser(adminRights: 1, on: app.db)

        try await app.testing().test(
          .POST, "cycles/colors",
          beforeRequest: { req in
            try authorize(&req, as: moderator)
            try req.content.encode(CreateCycleColorDTO(name: "Red", color: "FF0000"))
          },
          afterResponse: { res async throws in
            #expect(res.status == .forbidden)
            #expect(try await CycleColor.query(on: app.db).count() == 0)
          })
      }
    }

    @Test("Creating a color with an invalid hex code fails validation", arguments: ["FF000", "FF00000", "GG0000", "#FF000"])
    func createInvalidColor(color: String) async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)

        try await app.testing().test(
          .POST, "cycles/colors",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(CreateCycleColorDTO(name: "Red", color: color))
          },
          afterResponse: { res async throws in
            #expect(res.status == .badRequest)
            #expect(try await CycleColor.query(on: app.db).count() == 0)
          })
      }
    }

    @Test("Creating a color with a name already in use returns 409")
    func createDuplicateName() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)
        try await makeCycleColor(name: "Red", on: app.db)

        try await app.testing().test(
          .POST, "cycles/colors",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(CreateCycleColorDTO(name: "Red", color: "AA0000"))
          },
          afterResponse: { res async in
            #expect(res.status == .conflict)
          })
      }
    }

    // MARK: - PATCH /cycles/colors/:id

    @Test("Patching a color's name leaves its color untouched")
    func patchName() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)
        let color = try await makeCycleColor(name: "Red", color: "FF0000", on: app.db)

        try await app.testing().test(
          .PATCH, "cycles/colors/\(color.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(PatchCycleColorDTO(name: " Crimson "))
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let stored = try #require(try await CycleColor.find(color.id, on: app.db))
            #expect(stored.name == "Crimson")
            #expect(stored.color == "ff0000")
          })
      }
    }

    @Test("Patching a color with an invalid hex code fails validation")
    func patchInvalidColor() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)
        let color = try await makeCycleColor(color: "FF0000", on: app.db)

        try await app.testing().test(
          .PATCH, "cycles/colors/\(color.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(PatchCycleColorDTO(color: "nope"))
          },
          afterResponse: { res async throws in
            #expect(res.status == .badRequest)
            #expect(try await CycleColor.find(color.id, on: app.db)?.color == "ff0000")
          })
      }
    }

    @Test("Patching a color as a moderator is forbidden")
    func patchAsModerator() async throws {
      try await withAppIncludingDB { app in
        let moderator = try await makeUser(adminRights: 1, on: app.db)
        let color = try await makeCycleColor(name: "Red", on: app.db)

        try await app.testing().test(
          .PATCH, "cycles/colors/\(color.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: moderator)
            try req.content.encode(PatchCycleColorDTO(name: "Crimson"))
          },
          afterResponse: { res async throws in
            #expect(res.status == .forbidden)
            #expect(try await CycleColor.find(color.id, on: app.db)?.name == "Red")
          })
      }
    }

    @Test("Patching an unknown color returns 404")
    func patchUnknownID() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)

        try await app.testing().test(
          .PATCH, "cycles/colors/\(UUID())",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(PatchCycleColorDTO(name: "Crimson"))
          },
          afterResponse: { res async in
            #expect(res.status == .notFound)
          })
      }
    }

    @Test("Patching a color to a name already in use returns 409")
    func patchDuplicateName() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)
        try await makeCycleColor(name: "Red", on: app.db)
        let color = try await makeCycleColor(name: "Blue", color: "0000FF", on: app.db)

        try await app.testing().test(
          .PATCH, "cycles/colors/\(color.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(PatchCycleColorDTO(name: "Red"))
          },
          afterResponse: { res async in
            #expect(res.status == .conflict)
          })
      }
    }
  }
}
