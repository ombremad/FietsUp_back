@testable import FietsUp_back
import Fluent
import VaporTesting
import Testing

extension DatabaseTests {
  @Suite("Activity Controller Tests with DB", .serialized)
  struct ActivityControllerTests {
    private func activity(minutes: Int = 60, endingMinutesAgo: Int = 10, distance: Int = 10_000) -> CreateActivityDTO {
      let end = Date().addingTimeInterval(Double(-endingMinutesAgo * 60))
      return CreateActivityDTO(startDate: end.addingTimeInterval(Double(-minutes * 60)), endDate: end, distance: distance)
    }

    // MARK: - POST /activities

    @Test("Recording an activity requires a token")
    func createWithoutToken() async throws {
      try await withAppIncludingDB { app in
        try await app.testing().test(
          .POST, "activities",
          beforeRequest: { req in
            try req.content.encode(activity())
          },
          afterResponse: { res async throws in
            #expect(res.status == .unauthorized)
            #expect(try await Activity.query(on: app.db).count() == 0)
          })
      }
    }

    @Test("Recording my first activity of the week saves it, adds its distance and bumps my streak")
    func createFirstOfWeek() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)

        try await app.testing().test(
          .POST, "activities",
          beforeRequest: { req in
            try authorize(&req, as: user)
            try req.content.encode(activity(minutes: 90, distance: 25_000))
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let dto = try res.content.decode(GetActivityDTO.self)
            #expect(dto.length == 90)
            #expect(dto.distance == 25_000)
            #expect(dto.streakUpdated == true)
            let stored = try #require(try await User.find(user.id, on: app.db))
            #expect(stored.totalElapsedDistance == 25_000)
            #expect(stored.streak == 1)
            #expect(stored.streakUpdatedThisWeek)
          })
      }
    }

    @Test("Recording a second activity in the same week leaves my streak alone")
    func createSecondOfWeek() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)

        for _ in 0..<2 {
          try await app.testing().test(
            .POST, "activities",
            beforeRequest: { req in
              try authorize(&req, as: user)
              try req.content.encode(activity())
            },
            afterResponse: { res async in
              #expect(res.status == .ok)
            })
        }

        let stored = try #require(try await User.find(user.id, on: app.db))
        #expect(stored.streak == 1)
        #expect(stored.totalElapsedDistance == 20_000)

        try await app.testing().test(
          .POST, "activities",
          beforeRequest: { req in
            try authorize(&req, as: user)
            try req.content.encode(activity())
          },
          afterResponse: { res async throws in
            #expect(try res.content.decode(GetActivityDTO.self).streakUpdated == false)
          })
      }
    }

    @Test("Recording an activity that ends before it starts fails")
    func createEndBeforeStart() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let end = Date().addingTimeInterval(-3600)

        try await app.testing().test(
          .POST, "activities",
          beforeRequest: { req in
            try authorize(&req, as: user)
            try req.content.encode(CreateActivityDTO(startDate: end, endDate: end, distance: 1000))
          },
          afterResponse: { res async throws in
            #expect(res.status == .badRequest)
            #expect(try await Activity.query(on: app.db).count() == 0)
          })
      }
    }

    @Test("Recording an activity that ends in the future fails")
    func createEndInFuture() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)

        try await app.testing().test(
          .POST, "activities",
          beforeRequest: { req in
            try authorize(&req, as: user)
            try req.content.encode(activity(endingMinutesAgo: -60))
          },
          afterResponse: { res async throws in
            #expect(res.status == .badRequest)
            #expect(try await Activity.query(on: app.db).count() == 0)
          })
      }
    }

    @Test("Recording an activity with an out-of-range distance fails validation", arguments: [0, 720_001])
    func createInvalidDistance(distance: Int) async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)

        try await app.testing().test(
          .POST, "activities",
          beforeRequest: { req in
            try authorize(&req, as: user)
            try req.content.encode(activity(distance: distance))
          },
          afterResponse: { res async throws in
            #expect(res.status == .badRequest)
            #expect(try await Activity.query(on: app.db).count() == 0)
          })
      }
    }

    @Test("Recording an activity too long to store fails validation")
    func createTooLong() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)

        try await app.testing().test(
          .POST, "activities",
          beforeRequest: { req in
            try authorize(&req, as: user)
            try req.content.encode(activity(minutes: 32_768))
          },
          afterResponse: { res async in
            #expect(res.status == .badRequest)
          })
      }
    }

    // MARK: - GET /activities

    @Test("Listing activities returns only mine, latest first")
    func getAll() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let now = Date()
        try await makeActivity(start: now.addingTimeInterval(-7200), end: now.addingTimeInterval(-3600), distance: 1, by: user, on: app.db)
        try await makeActivity(start: now.addingTimeInterval(-1200), end: now.addingTimeInterval(-600), distance: 2, by: user, on: app.db)
        try await makeActivity(distance: 3, by: try await makeUser(on: app.db), on: app.db)

        try await app.testing().test(
          .GET, "activities",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            #expect(try res.content.decode(Page<GetActivityDTO>.self).items.map(\.distance) == [2, 1])
          })
      }
    }

    @Test("Listing activities can be limited to a date range")
    func getAllInRange() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let day: TimeInterval = 86_400
        let now = Date()
        try await makeActivity(start: now.addingTimeInterval(-10 * day), end: now.addingTimeInterval(-10 * day + 3600), distance: 1, by: user, on: app.db)
        try await makeActivity(start: now.addingTimeInterval(-5 * day), end: now.addingTimeInterval(-5 * day + 3600), distance: 2, by: user, on: app.db)
        try await makeActivity(start: now.addingTimeInterval(-1 * day), end: now.addingTimeInterval(-1 * day + 3600), distance: 3, by: user, on: app.db)

        try await app.testing().test(
          .GET, "activities",
          beforeRequest: { req in
            try authorize(&req, as: user)
            try req.query.encode(QueryActivityWithDateDTO(
              start: now.addingTimeInterval(-7 * day), end: now.addingTimeInterval(-2 * day), page: nil, per: nil))
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            #expect(try res.content.decode(Page<GetActivityDTO>.self).items.map(\.distance) == [2])
          })
      }
    }

    @Test("Listing activities honours page and per")
    func getAllPaginated() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let now = Date()
        for distance in 1...3 {
          let end = now.addingTimeInterval(Double(-distance * 3600))
          try await makeActivity(start: end.addingTimeInterval(-600), end: end, distance: distance, by: user, on: app.db)
        }

        try await app.testing().test(
          .GET, "activities?page=2&per=2",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let page = try res.content.decode(Page<GetActivityDTO>.self)
            #expect(page.items.map(\.distance) == [3])
            #expect(page.metadata.total == 3)
          })
      }
    }

    // MARK: - DELETE /activities/:id

    @Test("Deleting my activity removes it and its distance from my total")
    func delete() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        try await makeActivity(distance: 4_000, by: user, on: app.db)
        let activity = try await makeActivity(distance: 6_000, by: user, on: app.db)

        try await app.testing().test(
          .DELETE, "activities/\(activity.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async throws in
            #expect(res.status == .noContent)
            #expect(try await Activity.find(activity.id, on: app.db) == nil)
            #expect(try await User.find(user.id, on: app.db)?.totalElapsedDistance == 4_000)
          })
      }
    }

    @Test("Deleting someone else's activity returns 404")
    func deleteOthersActivity() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let activity = try await makeActivity(by: try await makeUser(on: app.db), on: app.db)

        try await app.testing().test(
          .DELETE, "activities/\(activity.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async throws in
            #expect(res.status == .notFound)
            #expect(try await Activity.find(activity.id, on: app.db) != nil)
          })
      }
    }

    @Test("Deleting an unknown activity returns 404")
    func deleteUnknownID() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)

        try await app.testing().test(
          .DELETE, "activities/\(UUID())",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async in
            #expect(res.status == .notFound)
          })
      }
    }
  }
}
