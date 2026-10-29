@testable import FietsUp_back
import Fluent
import VaporTesting
import Testing

extension DatabaseTests {
  @Suite("Report Controller Tests with DB", .serialized)
  struct ReportControllerTests {
    @Test("Listing all pending reports requires a token")
    func pendingWithoutToken() async throws {
      try await withAppIncludingDB { app in
        try await app.testing().test(.GET, "reports/pending") { res async in
          #expect(res.status == .unauthorized)
        }
      }
    }

    @Test("Listing all pending reports returns every kind, unprocessed only")
    func pending() async throws {
      try await withAppIncludingDB { app in
        let moderator = try await makeUser(adminRights: 1, on: app.db)
        let category = try await makeModerationCategory(on: app.db)
        let forumPost = try await makeForumPost(by: moderator, in: try await makeForumCategory(on: app.db), on: app.db)
        let forumComment = try await makeForumComment(by: moderator, on: forumPost, on: app.db)
        let dangerPost = try await makeDangerPost(by: moderator, in: try await makeDangerCategory(on: app.db), on: app.db)
        let dangerComment = try await makeDangerComment(by: moderator, on: dangerPost, on: app.db)
        let forumPostReport = try await makeReport(on: forumPost, by: moderator, category: category, on: app.db)
        let forumCommentReport = try await makeReport(on: forumComment, by: moderator, category: category, on: app.db)
        let dangerPostReport = try await makeReport(on: dangerPost, by: moderator, category: category, on: app.db)
        let dangerCommentReport = try await makeReport(on: dangerComment, by: moderator, category: category, on: app.db)
        let processed = try await makeReport(on: forumPost, by: try await makeUser(on: app.db), category: category, on: app.db)
        processed.process(with: ProcessReportDTO(details: "Done"))
        try await processed.save(on: app.db)

        try await app.testing().test(
          .GET, "reports/pending",
          beforeRequest: { req in
            try authorize(&req, as: moderator)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let dto = try res.content.decode(GetAllReportsDTO.self)
            #expect(dto.forumPosts.map(\.id) == [forumPostReport.id])
            #expect(dto.forumComments.map(\.id) == [forumCommentReport.id])
            #expect(dto.dangerPosts.map(\.id) == [dangerPostReport.id])
            #expect(dto.dangerComments.map(\.id) == [dangerCommentReport.id])
          })
      }
    }

    @Test("Listing all pending reports is forbidden to regular users")
    func pendingAsRegularUser() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)

        try await app.testing().test(
          .GET, "reports/pending",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async in
            #expect(res.status == .forbidden)
          })
      }
    }
  }
}
