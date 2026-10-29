@testable import FietsUp_back
import Fluent
import SQLKit
import VaporTesting
import Testing

extension DatabaseTests {
  @Suite("Database Trigger Tests with DB", .serialized)
  struct DatabaseTriggerTests {
    /// Whether a timestamp column was touched within the last day, computed by the server to avoid time zone shifts.
    private func isRecent(_ column: String, in table: String, id: UUID, on db: any Database) async throws -> Bool {
      struct Row: Decodable { let recent: Int }
      let sql = try #require(db as? any SQLDatabase)
      let row = try await sql.raw("""
        SELECT (\(ident: column) >= NOW() - INTERVAL 1 DAY) AS recent
        FROM \(ident: table) WHERE id = UNHEX(\(bind: id.hexString))
        """).first(decoding: Row.self)
      return try #require(row).recent == 1
    }

    // MARK: - Forum activity

    @Test("A new forum post bumps its category's last activity")
    func forumPostBumpsCategory() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let category = try await makeForumCategory(on: app.db)
        try await setDate("last_activity_date", in: "forum_categories", id: category.requireID(), secondsAgo: 2 * 86_400, on: app.db)

        try await makeForumPost(by: user, in: category, on: app.db)

        #expect(try await isRecent("last_activity_date", in: "forum_categories", id: category.requireID(), on: app.db))
      }
    }

    @Test("A new forum comment bumps its post's and its category's last activity")
    func forumCommentBumpsPostAndCategory() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let category = try await makeForumCategory(on: app.db)
        let post = try await makeForumPost(by: user, in: category, on: app.db)
        try await setDate("last_activity_date", in: "forum_posts", id: post.requireID(), secondsAgo: 2 * 86_400, on: app.db)
        try await setDate("last_activity_date", in: "forum_categories", id: category.requireID(), secondsAgo: 2 * 86_400, on: app.db)

        try await makeForumComment(by: user, on: post, on: app.db)

        #expect(try await isRecent("last_activity_date", in: "forum_posts", id: post.requireID(), on: app.db))
        #expect(try await isRecent("last_activity_date", in: "forum_categories", id: category.requireID(), on: app.db))
      }
    }

    // MARK: - Danger activity

    @Test("A new danger post bumps its category's last activity")
    func dangerPostBumpsCategory() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let category = try await makeDangerCategory(on: app.db)
        try await setDate("last_activity_date", in: "danger_categories", id: category.requireID(), secondsAgo: 2 * 86_400, on: app.db)

        try await makeDangerPost(by: user, in: category, on: app.db)

        #expect(try await isRecent("last_activity_date", in: "danger_categories", id: category.requireID(), on: app.db))
      }
    }

    @Test("A new danger comment bumps its post's and its category's last activity")
    func dangerCommentBumpsPostAndCategory() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let category = try await makeDangerCategory(on: app.db)
        let post = try await makeDangerPost(by: user, in: category, on: app.db)
        try await setDate("last_activity_date", in: "danger_posts", id: post.requireID(), secondsAgo: 2 * 86_400, on: app.db)
        try await setDate("last_activity_date", in: "danger_categories", id: category.requireID(), secondsAgo: 2 * 86_400, on: app.db)

        try await makeDangerComment(by: user, on: post, on: app.db)

        #expect(try await isRecent("last_activity_date", in: "danger_posts", id: post.requireID(), on: app.db))
        #expect(try await isRecent("last_activity_date", in: "danger_categories", id: category.requireID(), on: app.db))
      }
    }

    // MARK: - Weekly streak reset

    @Test("Resetting streaks zeroes inactive users, keeps active ones, and reopens everyone's week")
    func resetStreaks() async throws {
      try await withAppIncludingDB { app in
        let active = try await makeUser(on: app.db)
        let inactive = try await makeUser(on: app.db)
        for (user, streak) in [(active, 5), (inactive, 3)] {
          user.streak = streak
          user.streakUpdatedThisWeek = true
          try await user.save(on: app.db)
        }
        let day: TimeInterval = 86_400
        try await makeActivity(start: Date().addingTimeInterval(-2 * day), end: Date().addingTimeInterval(-2 * day + 3600), by: active, on: app.db)
        try await makeActivity(start: Date().addingTimeInterval(-10 * day), end: Date().addingTimeInterval(-10 * day + 3600), by: inactive, on: app.db)

        let sql = try #require(app.db as? any SQLDatabase)
        try await sql.raw("CALL reset_streaks()").run()

        let storedActive = try #require(try await User.find(active.id, on: app.db))
        let storedInactive = try #require(try await User.find(inactive.id, on: app.db))
        #expect(storedActive.streak == 5)
        #expect(storedInactive.streak == 0)
        #expect(!storedActive.streakUpdatedThisWeek)
        #expect(!storedInactive.streakUpdatedThisWeek)
      }
    }

    @Test("The weekly streak reset is scheduled")
    func weeklyEventScheduled() async throws {
      try await withAppIncludingDB { app in
        struct Row: Decodable { let total: Int }
        let sql = try #require(app.db as? any SQLDatabase)
        let row = try await sql.raw("""
          SELECT COUNT(*) AS total FROM information_schema.EVENTS
          WHERE EVENT_SCHEMA = DATABASE() AND EVENT_NAME = 'weekly_streak_update'
          """).first(decoding: Row.self)
        #expect(try #require(row).total == 1)
      }
    }
  }
}
