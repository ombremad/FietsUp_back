@testable import FietsUp_back
import Fluent
import VaporTesting
import Testing

extension DatabaseTests {
  @Suite("Forum Post Controller Tests with DB", .serialized)
  struct ForumPostControllerTests {
    // MARK: - POST /forum/posts/category/:forumCategoryID

    @Test("Creating a forum post requires a token")
    func createWithoutToken() async throws {
      try await withAppIncludingDB { app in
        let category = try await makeForumCategory(on: app.db)

        try await app.testing().test(
          .POST, "forum/posts/category/\(category.requireID())",
          beforeRequest: { req in
            try req.content.encode(CreateForumPostDTO(title: "Hello", content: "World"))
          },
          afterResponse: { res async throws in
            #expect(res.status == .unauthorized)
            #expect(try await ForumPost.query(on: app.db).count() == 0)
          })
      }
    }

    @Test("Creating a forum post saves it, trimmed, with me as its author")
    func create() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let category = try await makeForumCategory(on: app.db)

        try await app.testing().test(
          .POST, "forum/posts/category/\(category.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: user)
            try req.content.encode(CreateForumPostDTO(title: "  Hello  ", content: "  World  "))
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let dto = try res.content.decode(GetForumPostWithCommentsDTO.self)
            #expect(dto.title == "Hello")
            #expect(dto.content == "World")
            #expect(dto.user.id == user.id)
            #expect(dto.likeCount == 0)
            #expect(!dto.likedByUser)
            #expect(!dto.favedByUser)
            #expect(dto.comments.items.isEmpty)
            #expect(try await ForumPost.query(on: app.db).count() == 1)
          })
      }
    }

    @Test("Creating a forum post in an unknown category returns 404")
    func createUnknownCategory() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)

        try await app.testing().test(
          .POST, "forum/posts/category/\(UUID())",
          beforeRequest: { req in
            try authorize(&req, as: user)
            try req.content.encode(CreateForumPostDTO(title: "Hello", content: "World"))
          },
          afterResponse: { res async in
            #expect(res.status == .notFound)
          })
      }
    }

    @Test("Creating a forum post with an empty title fails validation")
    func createEmptyTitle() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let category = try await makeForumCategory(on: app.db)

        try await app.testing().test(
          .POST, "forum/posts/category/\(category.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: user)
            try req.content.encode(CreateForumPostDTO(title: "", content: "World"))
          },
          afterResponse: { res async throws in
            #expect(res.status == .badRequest)
            #expect(try await ForumPost.query(on: app.db).count() == 0)
          })
      }
    }

    @Test("Creating a forum post shows my selected cycle as its author")
    func createAuthorCycle() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let cycleType = try await selectCycle(for: user, on: app.db)
        let category = try await makeForumCategory(on: app.db)

        try await app.testing().test(
          .POST, "forum/posts/category/\(category.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: user)
            try req.content.encode(CreateForumPostDTO(title: "Hello", content: "World"))
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            #expect(try res.content.decode(GetForumPostWithCommentsDTO.self).user.cycleType?.id == cycleType.id)
          })
      }
    }

    // MARK: - POST /forum/posts/:id/like and /fav

    @Test("Liking a forum post twice toggles the like on and off")
    func likeToggle() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let post = try await makeForumPost(by: user, in: try await makeForumCategory(on: app.db), on: app.db)

        try await app.testing().test(
          .POST, "forum/posts/\(post.requireID())/like",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let dto = try res.content.decode(GetForumPostWithCommentsDTO.self)
            #expect(dto.likeCount == 1)
            #expect(dto.likedByUser)
          })

        try await app.testing().test(
          .POST, "forum/posts/\(post.requireID())/like",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let dto = try res.content.decode(GetForumPostWithCommentsDTO.self)
            #expect(dto.likeCount == 0)
            #expect(!dto.likedByUser)
          })
      }
    }

    @Test("Another user's like counts but isn't shown as mine")
    func likeByAnotherUser() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let other = try await makeUser(on: app.db)
        let post = try await makeForumPost(by: user, in: try await makeForumCategory(on: app.db), on: app.db)
        try await ForumPostLike(userID: other.requireID(), forumPostID: post.requireID()).save(on: app.db)

        try await app.testing().test(
          .GET, "forum/posts/\(post.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let dto = try res.content.decode(GetForumPostWithCommentsDTO.self)
            #expect(dto.likeCount == 1)
            #expect(!dto.likedByUser)
          })
      }
    }

    @Test("Faving a forum post twice toggles the fav on and off")
    func favToggle() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let post = try await makeForumPost(by: user, in: try await makeForumCategory(on: app.db), on: app.db)

        try await app.testing().test(
          .POST, "forum/posts/\(post.requireID())/fav",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            #expect(try res.content.decode(GetForumPostWithCommentsDTO.self).favedByUser)
          })

        try await app.testing().test(
          .POST, "forum/posts/\(post.requireID())/fav",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            #expect(!(try res.content.decode(GetForumPostWithCommentsDTO.self).favedByUser))
          })
      }
    }

    @Test("Liking an unknown forum post returns 404")
    func likeUnknownPost() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)

        try await app.testing().test(
          .POST, "forum/posts/\(UUID())/like",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async in
            #expect(res.status == .notFound)
          })
      }
    }

    @Test("Faving an unknown forum post returns 404")
    func favUnknownPost() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)

        try await app.testing().test(
          .POST, "forum/posts/\(UUID())/fav",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async in
            #expect(res.status == .notFound)
          })
      }
    }

    // MARK: - GET /forum/posts/:id

    @Test("Getting a forum post lists its comments oldest first, with my likes and favs")
    func getByID() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let post = try await makeForumPost(by: user, in: try await makeForumCategory(on: app.db), on: app.db)
        let second = try await makeForumComment(content: "Second", by: user, on: post, on: app.db)
        let first = try await makeForumComment(content: "First", by: user, on: post, on: app.db)
        try await setDate("creation_date", in: "forum_comments", id: first.requireID(), secondsAgo: 120, on: app.db)
        try await setDate("creation_date", in: "forum_comments", id: second.requireID(), secondsAgo: 60, on: app.db)
        try await ForumCommentLike(userID: user.requireID(), forumCommentID: second.requireID()).save(on: app.db)
        try await ForumCommentFav(userID: user.requireID(), forumCommentID: first.requireID()).save(on: app.db)

        try await app.testing().test(
          .GET, "forum/posts/\(post.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let comments = try res.content.decode(GetForumPostWithCommentsDTO.self).comments.items
            #expect(comments.map(\.content) == ["First", "Second"])
            #expect(comments.map(\.likeCount) == [0, 1])
            #expect(comments.map(\.likedByUser) == [false, true])
            #expect(comments.map(\.favedByUser) == [true, false])
          })
      }
    }

    @Test("Getting a forum post pages its comments")
    func getByIDPaginated() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let post = try await makeForumPost(by: user, in: try await makeForumCategory(on: app.db), on: app.db)
        for (index, content) in ["A", "B", "C"].enumerated() {
          let comment = try await makeForumComment(content: content, by: user, on: post, on: app.db)
          try await setDate("creation_date", in: "forum_comments", id: comment.requireID(), secondsAgo: (10 - index) * 60, on: app.db)
        }

        try await app.testing().test(
          .GET, "forum/posts/\(post.requireID())?page=2&per=2",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let comments = try res.content.decode(GetForumPostWithCommentsDTO.self).comments
            #expect(comments.items.map(\.content) == ["C"])
            #expect(comments.metadata.total == 3)
          })
      }
    }

    @Test("Getting an unknown forum post returns 404")
    func getByUnknownID() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)

        try await app.testing().test(
          .GET, "forum/posts/\(UUID())",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async in
            #expect(res.status == .notFound)
          })
      }
    }

    // MARK: - PATCH /forum/posts/:id

    @Test("Patching a forum post as a moderator updates it, trimmed")
    func patchAsModerator() async throws {
      try await withAppIncludingDB { app in
        let moderator = try await makeUser(adminRights: 1, on: app.db)
        let author = try await makeUser(on: app.db)
        let post = try await makeForumPost(title: "Hello", content: "World", by: author, in: try await makeForumCategory(on: app.db), on: app.db)

        try await app.testing().test(
          .PATCH, "forum/posts/\(post.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: moderator)
            try req.content.encode(PatchForumPostDTO(title: "  Edited  "))
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let stored = try #require(try await ForumPost.find(post.id, on: app.db))
            #expect(stored.title == "Edited")
            #expect(stored.content == "World")
          })
      }
    }

    @Test("Patching my own forum post as a regular user is forbidden")
    func patchAsAuthor() async throws {
      try await withAppIncludingDB { app in
        let author = try await makeUser(on: app.db)
        let post = try await makeForumPost(title: "Hello", by: author, in: try await makeForumCategory(on: app.db), on: app.db)

        try await app.testing().test(
          .PATCH, "forum/posts/\(post.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: author)
            try req.content.encode(PatchForumPostDTO(title: "Edited"))
          },
          afterResponse: { res async throws in
            #expect(res.status == .forbidden)
            #expect(try await ForumPost.find(post.id, on: app.db)?.title == "Hello")
          })
      }
    }

    @Test("Patching a forum post with an empty title fails validation")
    func patchEmptyTitle() async throws {
      try await withAppIncludingDB { app in
        let moderator = try await makeUser(adminRights: 1, on: app.db)
        let post = try await makeForumPost(title: "Hello", by: moderator, in: try await makeForumCategory(on: app.db), on: app.db)

        try await app.testing().test(
          .PATCH, "forum/posts/\(post.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: moderator)
            try req.content.encode(PatchForumPostDTO(title: ""))
          },
          afterResponse: { res async throws in
            #expect(res.status == .badRequest)
            #expect(try await ForumPost.find(post.id, on: app.db)?.title == "Hello")
          })
      }
    }

    @Test("Patching an unknown forum post returns 404")
    func patchUnknownID() async throws {
      try await withAppIncludingDB { app in
        let moderator = try await makeUser(adminRights: 1, on: app.db)

        try await app.testing().test(
          .PATCH, "forum/posts/\(UUID())",
          beforeRequest: { req in
            try authorize(&req, as: moderator)
            try req.content.encode(PatchForumPostDTO(title: "Edited"))
          },
          afterResponse: { res async in
            #expect(res.status == .notFound)
          })
      }
    }

    // MARK: - DELETE /forum/posts/:id

    @Test("Deleting a forum post as a moderator deletes its comments and keeps its reports")
    func deleteAsModerator() async throws {
      try await withAppIncludingDB { app in
        let moderator = try await makeUser(adminRights: 1, on: app.db)
        let author = try await makeUser(on: app.db)
        let post = try await makeForumPost(by: author, in: try await makeForumCategory(on: app.db), on: app.db)
        try await makeForumComment(by: author, on: post, on: app.db)
        let report = try await makeReport(on: post, by: moderator, category: try await makeModerationCategory(on: app.db), on: app.db)

        try await app.testing().test(
          .DELETE, "forum/posts/\(post.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: moderator)
          },
          afterResponse: { res async throws in
            #expect(res.status == .noContent)
            #expect(try await ForumPost.find(post.id, on: app.db) == nil)
            #expect(try await ForumComment.query(on: app.db).count() == 0)
            let storedReport = try #require(try await ForumPostReport.find(report.id, on: app.db))
            #expect(storedReport.$forumPost.id == nil)
          })
      }
    }

    @Test("Deleting my own forum post as a regular user is forbidden")
    func deleteAsAuthor() async throws {
      try await withAppIncludingDB { app in
        let author = try await makeUser(on: app.db)
        let post = try await makeForumPost(by: author, in: try await makeForumCategory(on: app.db), on: app.db)

        try await app.testing().test(
          .DELETE, "forum/posts/\(post.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: author)
          },
          afterResponse: { res async throws in
            #expect(res.status == .forbidden)
            #expect(try await ForumPost.find(post.id, on: app.db) != nil)
          })
      }
    }

    @Test("Deleting an unknown forum post returns 404")
    func deleteUnknownID() async throws {
      try await withAppIncludingDB { app in
        let moderator = try await makeUser(adminRights: 1, on: app.db)

        try await app.testing().test(
          .DELETE, "forum/posts/\(UUID())",
          beforeRequest: { req in
            try authorize(&req, as: moderator)
          },
          afterResponse: { res async in
            #expect(res.status == .notFound)
          })
      }
    }
  }
}
