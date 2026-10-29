@testable import FietsUp_back
import Fluent
import VaporTesting
import Testing

extension DatabaseTests {
  @Suite("Forum Category Controller Tests with DB", .serialized)
  struct ForumCategoryControllerTests {
    // MARK: - GET /forum/categories

    @Test("Listing forum categories requires a token")
    func getIndexWithoutToken() async throws {
      try await withAppIncludingDB { app in
        try await app.testing().test(.GET, "forum/categories") { res async in
          #expect(res.status == .unauthorized)
        }
      }
    }

    @Test("Listing forum categories sorts them by last activity and counts their posts")
    func getIndex() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let old = try await makeForumCategory(name: "Old", on: app.db)
        let recent = try await makeForumCategory(name: "Recent", on: app.db)
        let empty = try await makeForumCategory(name: "Empty", on: app.db)
        try await makeForumPost(by: user, in: old, on: app.db)
        try await makeForumPost(by: user, in: recent, on: app.db)
        try await makeForumPost(by: user, in: recent, on: app.db)
        try await setDate("last_activity_date", in: "forum_categories", id: old.requireID(), secondsAgo: 3600, on: app.db)
        try await setDate("last_activity_date", in: "forum_categories", id: recent.requireID(), secondsAgo: 0, on: app.db)
        try await setDate("last_activity_date", in: "forum_categories", id: empty.requireID(), secondsAgo: 7200, on: app.db)

        try await app.testing().test(
          .GET, "forum/categories",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let dtos = try res.content.decode([GetForumCategoryWithCountsDTO].self)
            #expect(dtos.map(\.name) == ["Recent", "Old", "Empty"])
            #expect(dtos.map(\.totalPosts) == [2, 1, 0])
          })
      }
    }

    // MARK: - POST /forum/categories

    @Test("Creating a forum category as an admin trims and saves it")
    func createAsAdmin() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)

        try await app.testing().test(
          .POST, "forum/categories",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(CreateForumCategoryDTO(name: "  General  ", details: "  About bikes  "))
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let dto = try res.content.decode(GetForumCategoryShortDTO.self)
            #expect(dto.name == "General")
            #expect(dto.details == "About bikes")
            #expect(try await ForumCategory.query(on: app.db).count() == 1)
          })
      }
    }

    @Test("Creating a forum category without details leaves them empty")
    func createWithoutDetails() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)

        try await app.testing().test(
          .POST, "forum/categories",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(CreateForumCategoryDTO(name: "General", details: nil))
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            #expect(try res.content.decode(GetForumCategoryShortDTO.self).details == nil)
          })
      }
    }

    @Test("Creating a forum category as a moderator is forbidden")
    func createAsModerator() async throws {
      try await withAppIncludingDB { app in
        let moderator = try await makeUser(adminRights: 1, on: app.db)

        try await app.testing().test(
          .POST, "forum/categories",
          beforeRequest: { req in
            try authorize(&req, as: moderator)
            try req.content.encode(CreateForumCategoryDTO(name: "General", details: nil))
          },
          afterResponse: { res async throws in
            #expect(res.status == .forbidden)
            #expect(try await ForumCategory.query(on: app.db).count() == 0)
          })
      }
    }

    @Test("Creating a forum category with an empty name fails validation")
    func createEmptyName() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)

        try await app.testing().test(
          .POST, "forum/categories",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(CreateForumCategoryDTO(name: "", details: nil))
          },
          afterResponse: { res async throws in
            #expect(res.status == .badRequest)
            #expect(try await ForumCategory.query(on: app.db).count() == 0)
          })
      }
    }

    @Test("Creating a forum category with a name already in use returns 409")
    func createDuplicateName() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)
        try await makeForumCategory(name: "General", on: app.db)

        try await app.testing().test(
          .POST, "forum/categories",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(CreateForumCategoryDTO(name: "General", details: nil))
          },
          afterResponse: { res async in
            #expect(res.status == .conflict)
          })
      }
    }

    // MARK: - GET /forum/categories/:id

    @Test("Getting a forum category pages its posts by last activity with comment counts")
    func getByID() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let category = try await makeForumCategory(name: "General", details: "About bikes", on: app.db)
        let quiet = try await makeForumPost(title: "Quiet", by: user, in: category, on: app.db)
        let busy = try await makeForumPost(title: "Busy", by: user, in: category, on: app.db)
        try await makeForumComment(by: user, on: busy, on: app.db)
        try await makeForumComment(by: user, on: busy, on: app.db)
        try await setDate("last_activity_date", in: "forum_posts", id: quiet.requireID(), secondsAgo: 3600, on: app.db)
        try await setDate("last_activity_date", in: "forum_posts", id: busy.requireID(), secondsAgo: 0, on: app.db)

        try await app.testing().test(
          .GET, "forum/categories/\(category.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let dto = try res.content.decode(GetForumCategoryWithPostsDTO.self)
            #expect(dto.name == "General")
            #expect(dto.details == "About bikes")
            #expect(dto.posts.items.map(\.title) == ["Busy", "Quiet"])
            #expect(dto.posts.items.map(\.totalComments) == [2, 0])
            #expect(dto.posts.metadata.total == 2)
          })
      }
    }

    @Test("Getting a forum category honours page and per")
    func getByIDPaginated() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let category = try await makeForumCategory(on: app.db)
        for (index, title) in ["A", "B", "C"].enumerated() {
          let post = try await makeForumPost(title: title, by: user, in: category, on: app.db)
          try await setDate("last_activity_date", in: "forum_posts", id: post.requireID(), secondsAgo: index * 60, on: app.db)
        }

        try await app.testing().test(
          .GET, "forum/categories/\(category.requireID())?page=2&per=2",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let dto = try res.content.decode(GetForumCategoryWithPostsDTO.self)
            #expect(dto.posts.items.map(\.title) == ["C"])
            #expect(dto.posts.metadata.page == 2)
          })
      }
    }

    @Test("Getting a forum category with more than 25 posts per page fails validation")
    func getByIDPerTooLarge() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let category = try await makeForumCategory(on: app.db)

        try await app.testing().test(
          .GET, "forum/categories/\(category.requireID())?per=26",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async in
            #expect(res.status == .badRequest)
          })
      }
    }

    @Test("Getting an unknown forum category returns 404")
    func getByUnknownID() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)

        try await app.testing().test(
          .GET, "forum/categories/\(UUID())",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async in
            #expect(res.status == .notFound)
          })
      }
    }

    @Test("Getting a forum category shows each post author's selected cycle")
    func getByIDAuthorCycle() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let cycleType = try await selectCycle(for: user, on: app.db)
        let category = try await makeForumCategory(on: app.db)
        try await makeForumPost(by: user, in: category, on: app.db)

        try await app.testing().test(
          .GET, "forum/categories/\(category.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let dto = try res.content.decode(GetForumCategoryWithPostsDTO.self)
            #expect(dto.posts.items.first?.user.cycleType?.id == cycleType.id)
          })
      }
    }

    // MARK: - PATCH /forum/categories/:id

    @Test("Patching only a forum category's name keeps its details")
    func patchNameKeepsDetails() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)
        let category = try await makeForumCategory(name: "General", details: "About bikes", on: app.db)

        try await app.testing().test(
          .PATCH, "forum/categories/\(category.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            req.headers.contentType = .json
            req.body = ByteBuffer(string: #"{"name": " Talk "}"#)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let stored = try #require(try await ForumCategory.find(category.id, on: app.db))
            #expect(stored.name == "Talk")
            #expect(stored.details == "About bikes")
          })
      }
    }

    @Test("Patching a forum category's details to null clears them")
    func patchDetailsNull() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)
        let category = try await makeForumCategory(details: "About bikes", on: app.db)

        try await app.testing().test(
          .PATCH, "forum/categories/\(category.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            req.headers.contentType = .json
            req.body = ByteBuffer(string: #"{"details": null}"#)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            #expect(try await ForumCategory.find(category.id, on: app.db)?.details == nil)
          })
      }
    }

    @Test("Patching a forum category's details sets them, trimmed")
    func patchDetailsValue() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)
        let category = try await makeForumCategory(details: nil, on: app.db)

        try await app.testing().test(
          .PATCH, "forum/categories/\(category.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            req.headers.contentType = .json
            req.body = ByteBuffer(string: #"{"details": "  New details  "}"#)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            #expect(try await ForumCategory.find(category.id, on: app.db)?.details == "New details")
          })
      }
    }

    @Test("Patching a forum category as a moderator is forbidden")
    func patchAsModerator() async throws {
      try await withAppIncludingDB { app in
        let moderator = try await makeUser(adminRights: 1, on: app.db)
        let category = try await makeForumCategory(name: "General", on: app.db)

        try await app.testing().test(
          .PATCH, "forum/categories/\(category.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: moderator)
            try req.content.encode(PatchForumCategoryDTO(name: "Talk"))
          },
          afterResponse: { res async throws in
            #expect(res.status == .forbidden)
            #expect(try await ForumCategory.find(category.id, on: app.db)?.name == "General")
          })
      }
    }

    @Test("Patching an unknown forum category returns 404")
    func patchUnknownID() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)

        try await app.testing().test(
          .PATCH, "forum/categories/\(UUID())",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(PatchForumCategoryDTO(name: "Talk"))
          },
          afterResponse: { res async in
            #expect(res.status == .notFound)
          })
      }
    }

    @Test("Patching a forum category to a name already in use returns 409")
    func patchDuplicateName() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)
        try await makeForumCategory(name: "General", on: app.db)
        let category = try await makeForumCategory(name: "Talk", on: app.db)

        try await app.testing().test(
          .PATCH, "forum/categories/\(category.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(PatchForumCategoryDTO(name: "General"))
          },
          afterResponse: { res async in
            #expect(res.status == .conflict)
          })
      }
    }

    // MARK: - DELETE /forum/categories/:id

    @Test("Deleting a forum category also deletes its posts and their comments")
    func deleteAsAdmin() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)
        let category = try await makeForumCategory(on: app.db)
        let post = try await makeForumPost(by: admin, in: category, on: app.db)
        try await makeForumComment(by: admin, on: post, on: app.db)

        try await app.testing().test(
          .DELETE, "forum/categories/\(category.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: admin)
          },
          afterResponse: { res async throws in
            #expect(res.status == .noContent)
            #expect(try await ForumCategory.query(on: app.db).count() == 0)
            #expect(try await ForumPost.query(on: app.db).count() == 0)
            #expect(try await ForumComment.query(on: app.db).count() == 0)
          })
      }
    }

    @Test("Deleting a forum category as a moderator is forbidden")
    func deleteAsModerator() async throws {
      try await withAppIncludingDB { app in
        let moderator = try await makeUser(adminRights: 1, on: app.db)
        let category = try await makeForumCategory(on: app.db)

        try await app.testing().test(
          .DELETE, "forum/categories/\(category.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: moderator)
          },
          afterResponse: { res async throws in
            #expect(res.status == .forbidden)
            #expect(try await ForumCategory.find(category.id, on: app.db) != nil)
          })
      }
    }

    @Test("Deleting an unknown forum category returns 404")
    func deleteUnknownID() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)

        try await app.testing().test(
          .DELETE, "forum/categories/\(UUID())",
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
