@testable import FietsUp_back
import Fluent
import VaporTesting
import Testing

extension DatabaseTests {
  @Suite("Forum Comment Controller Tests with DB", .serialized)
  struct ForumCommentControllerTests {
    private func makePost(by user: User, on db: any Database) async throws -> ForumPost {
      try await makeForumPost(by: user, in: try await makeForumCategory(on: db), on: db)
    }

    // MARK: - POST /forum/comments/post/:forumPostID

    @Test("Commenting a forum post requires a token")
    func createWithoutToken() async throws {
      try await withAppIncludingDB { app in
        let post = try await makePost(by: try await makeUser(on: app.db), on: app.db)

        try await app.testing().test(
          .POST, "forum/comments/post/\(post.requireID())",
          beforeRequest: { req in
            try req.content.encode(CreateForumCommentDTO(content: "Nice"))
          },
          afterResponse: { res async throws in
            #expect(res.status == .unauthorized)
            #expect(try await ForumComment.query(on: app.db).count() == 0)
          })
      }
    }

    @Test("Commenting a forum post returns the post with my comment, trimmed")
    func create() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let post = try await makePost(by: user, on: app.db)

        try await app.testing().test(
          .POST, "forum/comments/post/\(post.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: user)
            try req.content.encode(CreateForumCommentDTO(content: "  Nice  "))
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let comments = try res.content.decode(GetForumPostWithCommentsDTO.self).comments.items
            #expect(comments.map(\.content) == ["Nice"])
            #expect(comments.first?.user.id == user.id)
          })
      }
    }

    @Test("Commenting an unknown forum post returns 404")
    func createUnknownPost() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)

        try await app.testing().test(
          .POST, "forum/comments/post/\(UUID())",
          beforeRequest: { req in
            try authorize(&req, as: user)
            try req.content.encode(CreateForumCommentDTO(content: "Nice"))
          },
          afterResponse: { res async in
            #expect(res.status == .notFound)
          })
      }
    }

    @Test("Commenting with empty content fails validation")
    func createEmptyContent() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let post = try await makePost(by: user, on: app.db)

        try await app.testing().test(
          .POST, "forum/comments/post/\(post.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: user)
            try req.content.encode(CreateForumCommentDTO(content: ""))
          },
          afterResponse: { res async throws in
            #expect(res.status == .badRequest)
            #expect(try await ForumComment.query(on: app.db).count() == 0)
          })
      }
    }

    // MARK: - POST /forum/comments/:id/like and /fav

    @Test("Liking a forum comment twice toggles the like on and off")
    func likeToggle() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let comment = try await makeForumComment(by: user, on: try await makePost(by: user, on: app.db), on: app.db)

        try await app.testing().test(
          .POST, "forum/comments/\(comment.requireID())/like",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let dto = try #require(try res.content.decode(GetForumPostWithCommentsDTO.self).comments.items.first)
            #expect(dto.likeCount == 1)
            #expect(dto.likedByUser)
          })

        try await app.testing().test(
          .POST, "forum/comments/\(comment.requireID())/like",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let dto = try #require(try res.content.decode(GetForumPostWithCommentsDTO.self).comments.items.first)
            #expect(dto.likeCount == 0)
            #expect(!dto.likedByUser)
          })
      }
    }

    @Test("Faving a forum comment twice toggles the fav on and off")
    func favToggle() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let comment = try await makeForumComment(by: user, on: try await makePost(by: user, on: app.db), on: app.db)

        try await app.testing().test(
          .POST, "forum/comments/\(comment.requireID())/fav",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            #expect(try #require(try res.content.decode(GetForumPostWithCommentsDTO.self).comments.items.first).favedByUser)
          })

        try await app.testing().test(
          .POST, "forum/comments/\(comment.requireID())/fav",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            #expect(!(try #require(try res.content.decode(GetForumPostWithCommentsDTO.self).comments.items.first).favedByUser))
          })
      }
    }

    @Test("Liking an unknown forum comment returns 404")
    func likeUnknownComment() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)

        try await app.testing().test(
          .POST, "forum/comments/\(UUID())/like",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async in
            #expect(res.status == .notFound)
          })
      }
    }

    @Test("Faving an unknown forum comment returns 404")
    func favUnknownComment() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)

        try await app.testing().test(
          .POST, "forum/comments/\(UUID())/fav",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async in
            #expect(res.status == .notFound)
          })
      }
    }

    // MARK: - PATCH /forum/comments/:id

    @Test("Patching a forum comment as a moderator updates it, trimmed")
    func patchAsModerator() async throws {
      try await withAppIncludingDB { app in
        let moderator = try await makeUser(adminRights: 1, on: app.db)
        let author = try await makeUser(on: app.db)
        let comment = try await makeForumComment(content: "Original", by: author, on: try await makePost(by: author, on: app.db), on: app.db)

        try await app.testing().test(
          .PATCH, "forum/comments/\(comment.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: moderator)
            try req.content.encode(PatchForumCommentDTO(content: "  Edited  "))
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            #expect(try res.content.decode(GetForumCommentDTO.self).content == "Edited")
            #expect(try await ForumComment.find(comment.id, on: app.db)?.content == "Edited")
          })
      }
    }

    @Test("Patching my own forum comment as a regular user is forbidden")
    func patchAsAuthor() async throws {
      try await withAppIncludingDB { app in
        let author = try await makeUser(on: app.db)
        let comment = try await makeForumComment(content: "Original", by: author, on: try await makePost(by: author, on: app.db), on: app.db)

        try await app.testing().test(
          .PATCH, "forum/comments/\(comment.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: author)
            try req.content.encode(PatchForumCommentDTO(content: "Edited"))
          },
          afterResponse: { res async throws in
            #expect(res.status == .forbidden)
            #expect(try await ForumComment.find(comment.id, on: app.db)?.content == "Original")
          })
      }
    }

    @Test("Patching a forum comment with empty content fails validation")
    func patchEmptyContent() async throws {
      try await withAppIncludingDB { app in
        let moderator = try await makeUser(adminRights: 1, on: app.db)
        let comment = try await makeForumComment(content: "Original", by: moderator, on: try await makePost(by: moderator, on: app.db), on: app.db)

        try await app.testing().test(
          .PATCH, "forum/comments/\(comment.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: moderator)
            try req.content.encode(PatchForumCommentDTO(content: ""))
          },
          afterResponse: { res async throws in
            #expect(res.status == .badRequest)
            #expect(try await ForumComment.find(comment.id, on: app.db)?.content == "Original")
          })
      }
    }

    @Test("Patching an unknown forum comment returns 404")
    func patchUnknownID() async throws {
      try await withAppIncludingDB { app in
        let moderator = try await makeUser(adminRights: 1, on: app.db)

        try await app.testing().test(
          .PATCH, "forum/comments/\(UUID())",
          beforeRequest: { req in
            try authorize(&req, as: moderator)
            try req.content.encode(PatchForumCommentDTO(content: "Edited"))
          },
          afterResponse: { res async in
            #expect(res.status == .notFound)
          })
      }
    }

    // MARK: - DELETE /forum/comments/:id

    @Test("Deleting a forum comment as a moderator removes it")
    func deleteAsModerator() async throws {
      try await withAppIncludingDB { app in
        let moderator = try await makeUser(adminRights: 1, on: app.db)
        let author = try await makeUser(on: app.db)
        let comment = try await makeForumComment(by: author, on: try await makePost(by: author, on: app.db), on: app.db)

        try await app.testing().test(
          .DELETE, "forum/comments/\(comment.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: moderator)
          },
          afterResponse: { res async throws in
            #expect(res.status == .noContent)
            #expect(try await ForumComment.find(comment.id, on: app.db) == nil)
          })
      }
    }

    @Test("Deleting my own forum comment as a regular user is forbidden")
    func deleteAsAuthor() async throws {
      try await withAppIncludingDB { app in
        let author = try await makeUser(on: app.db)
        let comment = try await makeForumComment(by: author, on: try await makePost(by: author, on: app.db), on: app.db)

        try await app.testing().test(
          .DELETE, "forum/comments/\(comment.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: author)
          },
          afterResponse: { res async throws in
            #expect(res.status == .forbidden)
            #expect(try await ForumComment.find(comment.id, on: app.db) != nil)
          })
      }
    }

    @Test("Deleting an unknown forum comment returns 404")
    func deleteUnknownID() async throws {
      try await withAppIncludingDB { app in
        let moderator = try await makeUser(adminRights: 1, on: app.db)

        try await app.testing().test(
          .DELETE, "forum/comments/\(UUID())",
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
