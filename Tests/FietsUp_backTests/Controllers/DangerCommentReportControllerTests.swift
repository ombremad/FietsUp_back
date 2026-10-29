@testable import FietsUp_back
import Fluent
import VaporTesting
import Testing

extension DatabaseTests {
  @Suite("Danger Comment Report Controller Tests with DB", .serialized)
  struct DangerCommentReportControllerTests {
    private func makeTarget(by user: User, on db: any Database) async throws -> DangerComment {
      let post = try await makeDangerPost(by: user, in: try await makeDangerCategory(on: db), on: db)
      return try await makeDangerComment(by: user, on: post, on: db)
    }

    // MARK: - POST /reports/dangers/comments/:id

    @Test("Reporting saves the report with me as reporter, trimmed")
    func create() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let target = try await makeTarget(by: user, on: app.db)
        let category = try await makeModerationCategory(on: app.db)

        try await app.testing().test(
          .POST, "reports/dangers/comments/\(target.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: user)
            try req.content.encode(CreateReportDTO(details: "  Offensive  ", categoryId: category.requireID()))
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let dto = try res.content.decode(GetDangerCommentReportDTO.self)
            #expect(dto.details == "Offensive")
            #expect(dto.user.id == user.id)
            #expect(dto.category.id == category.id)
            #expect(dto.dangerComment?.id == target.id)
            #expect(dto.processDate == nil)
          })
      }
    }

    @Test("Reporting requires a token")
    func createWithoutToken() async throws {
      try await withAppIncludingDB { app in
        let target = try await makeTarget(by: try await makeUser(on: app.db), on: app.db)
        let category = try await makeModerationCategory(on: app.db)

        try await app.testing().test(
          .POST, "reports/dangers/comments/\(target.requireID())",
          beforeRequest: { req in
            try req.content.encode(CreateReportDTO(details: nil, categoryId: category.requireID()))
          },
          afterResponse: { res async throws in
            #expect(res.status == .unauthorized)
            #expect(try await DangerCommentReport.query(on: app.db).count() == 0)
          })
      }
    }

    @Test("Reporting with details longer than 10000 characters fails validation")
    func createDetailsTooLong() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let target = try await makeTarget(by: user, on: app.db)
        let category = try await makeModerationCategory(on: app.db)

        try await app.testing().test(
          .POST, "reports/dangers/comments/\(target.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: user)
            try req.content.encode(CreateReportDTO(details: String(repeating: "a", count: 10_001), categoryId: category.requireID()))
          },
          afterResponse: { res async throws in
            #expect(res.status == .badRequest)
            #expect(try await DangerCommentReport.query(on: app.db).count() == 0)
          })
      }
    }

    @Test("Reporting an unknown item returns 404")
    func createUnknownTarget() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let category = try await makeModerationCategory(on: app.db)

        try await app.testing().test(
          .POST, "reports/dangers/comments/\(UUID())",
          beforeRequest: { req in
            try authorize(&req, as: user)
            try req.content.encode(CreateReportDTO(details: nil, categoryId: category.requireID()))
          },
          afterResponse: { res async in
            #expect(res.status == .notFound)
          })
      }
    }

    @Test("Reporting with an unknown moderation category returns 404")
    func createUnknownCategory() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let target = try await makeTarget(by: user, on: app.db)

        try await app.testing().test(
          .POST, "reports/dangers/comments/\(target.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: user)
            try req.content.encode(CreateReportDTO(details: nil, categoryId: UUID()))
          },
          afterResponse: { res async in
            #expect(res.status == .notFound)
          })
      }
    }

    @Test("Reporting the same item twice while my first report is pending returns 409")
    func createDuplicate() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let target = try await makeTarget(by: user, on: app.db)
        let category = try await makeModerationCategory(on: app.db)
        try await makeReport(on: target, by: user, category: category, on: app.db)

        try await app.testing().test(
          .POST, "reports/dangers/comments/\(target.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: user)
            try req.content.encode(CreateReportDTO(details: nil, categoryId: category.requireID()))
          },
          afterResponse: { res async throws in
            #expect(res.status == .conflict)
            #expect(try await DangerCommentReport.query(on: app.db).count() == 1)
          })
      }
    }

    // MARK: - GET /reports/dangers/comments/pending

    @Test("Pending reports list only unprocessed reports, oldest first")
    func pending() async throws {
      try await withAppIncludingDB { app in
        let moderator = try await makeUser(adminRights: 1, on: app.db)
        let target = try await makeTarget(by: moderator, on: app.db)
        let category = try await makeModerationCategory(on: app.db)
        let newer = try await makeReport(on: target, by: try await makeUser(on: app.db), category: category, on: app.db)
        let older = try await makeReport(on: target, by: try await makeUser(on: app.db), category: category, on: app.db)
        let processed = try await makeReport(on: target, by: try await makeUser(on: app.db), category: category, on: app.db)
        try await setDate("creation_date", in: DangerCommentReport.schema, id: older.requireID(), secondsAgo: 120, on: app.db)
        try await setDate("creation_date", in: DangerCommentReport.schema, id: newer.requireID(), secondsAgo: 60, on: app.db)
        processed.process(with: ProcessReportDTO(details: "Done"))
        try await processed.save(on: app.db)

        try await app.testing().test(
          .GET, "reports/dangers/comments/pending",
          beforeRequest: { req in
            try authorize(&req, as: moderator)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            #expect(try res.content.decode([GetDangerCommentReportDTO].self).map(\.id) == [older.id, newer.id])
          })
      }
    }

    @Test("Pending reports show the reporter's selected cycle")
    func pendingReporterCycle() async throws {
      try await withAppIncludingDB { app in
        let moderator = try await makeUser(adminRights: 1, on: app.db)
        let reporter = try await makeUser(on: app.db)
        let cycleType = try await selectCycle(for: reporter, on: app.db)
        try await makeReport(on: try await makeTarget(by: moderator, on: app.db), by: reporter, category: try await makeModerationCategory(on: app.db), on: app.db)

        try await app.testing().test(
          .GET, "reports/dangers/comments/pending",
          beforeRequest: { req in
            try authorize(&req, as: moderator)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            #expect(try res.content.decode([GetDangerCommentReportDTO].self).first?.user.cycleType?.id == cycleType.id)
          })
      }
    }

    @Test("Pending reports are forbidden to regular users")
    func pendingAsRegularUser() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)

        try await app.testing().test(
          .GET, "reports/dangers/comments/pending",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async in
            #expect(res.status == .forbidden)
          })
      }
    }

    @Test("A report stays listed after the reported item is deleted")
    func pendingAfterTargetDeleted() async throws {
      try await withAppIncludingDB { app in
        let moderator = try await makeUser(adminRights: 1, on: app.db)
        let target = try await makeTarget(by: moderator, on: app.db)
        let report = try await makeReport(on: target, by: moderator, category: try await makeModerationCategory(on: app.db), on: app.db)
        try await target.delete(on: app.db)

        try await app.testing().test(
          .GET, "reports/dangers/comments/pending",
          beforeRequest: { req in
            try authorize(&req, as: moderator)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let dtos = try res.content.decode([GetDangerCommentReportDTO].self)
            #expect(dtos.map(\.id) == [report.id])
            #expect(dtos.first?.dangerComment == nil)
          })
      }
    }

    // MARK: - PATCH /reports/dangers/comments/process/:reportID

    @Test("Processing a report records the decision, trimmed, and the date")
    func process() async throws {
      try await withAppIncludingDB { app in
        let moderator = try await makeUser(adminRights: 1, on: app.db)
        let report = try await makeReport(on: try await makeTarget(by: moderator, on: app.db), by: moderator, category: try await makeModerationCategory(on: app.db), on: app.db)

        try await app.testing().test(
          .PATCH, "reports/dangers/comments/process/\(report.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: moderator)
            try req.content.encode(ProcessReportDTO(details: "  Removed  "))
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let dto = try res.content.decode(GetDangerCommentReportDTO.self)
            #expect(dto.processDetails == "Removed")
            #expect(dto.processDate != nil)
          })
      }
    }

    @Test("Processing a report twice fails")
    func processTwice() async throws {
      try await withAppIncludingDB { app in
        let moderator = try await makeUser(adminRights: 1, on: app.db)
        let report = try await makeReport(on: try await makeTarget(by: moderator, on: app.db), by: moderator, category: try await makeModerationCategory(on: app.db), on: app.db)
        report.process(with: ProcessReportDTO(details: "First"))
        try await report.save(on: app.db)

        try await app.testing().test(
          .PATCH, "reports/dangers/comments/process/\(report.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: moderator)
            try req.content.encode(ProcessReportDTO(details: "Second"))
          },
          afterResponse: { res async throws in
            #expect(res.status == .badRequest)
            #expect(try await DangerCommentReport.find(report.id, on: app.db)?.processDetails == "First")
          })
      }
    }

    @Test("Processing a report without details fails validation")
    func processEmptyDetails() async throws {
      try await withAppIncludingDB { app in
        let moderator = try await makeUser(adminRights: 1, on: app.db)
        let report = try await makeReport(on: try await makeTarget(by: moderator, on: app.db), by: moderator, category: try await makeModerationCategory(on: app.db), on: app.db)

        try await app.testing().test(
          .PATCH, "reports/dangers/comments/process/\(report.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: moderator)
            try req.content.encode(ProcessReportDTO(details: ""))
          },
          afterResponse: { res async throws in
            #expect(res.status == .badRequest)
            #expect(try await DangerCommentReport.find(report.id, on: app.db)?.processDate == nil)
          })
      }
    }

    @Test("Processing an unknown report returns 404")
    func processUnknownID() async throws {
      try await withAppIncludingDB { app in
        let moderator = try await makeUser(adminRights: 1, on: app.db)

        try await app.testing().test(
          .PATCH, "reports/dangers/comments/process/\(UUID())",
          beforeRequest: { req in
            try authorize(&req, as: moderator)
            try req.content.encode(ProcessReportDTO(details: "Removed"))
          },
          afterResponse: { res async in
            #expect(res.status == .notFound)
          })
      }
    }

    @Test("Processing a report as a regular user is forbidden")
    func processAsRegularUser() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let report = try await makeReport(on: try await makeTarget(by: user, on: app.db), by: user, category: try await makeModerationCategory(on: app.db), on: app.db)

        try await app.testing().test(
          .PATCH, "reports/dangers/comments/process/\(report.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: user)
            try req.content.encode(ProcessReportDTO(details: "Removed"))
          },
          afterResponse: { res async throws in
            #expect(res.status == .forbidden)
            #expect(try await DangerCommentReport.find(report.id, on: app.db)?.processDate == nil)
          })
      }
    }
  }
}
