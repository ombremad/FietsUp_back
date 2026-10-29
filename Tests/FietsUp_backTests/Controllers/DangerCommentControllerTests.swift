@testable import FietsUp_back
import Fluent
import VaporTesting
import Testing

extension DatabaseTests {
  @Suite("Danger Comment Controller Tests with DB", .serialized)
  struct DangerCommentControllerTests {
    private func makePost(by user: User, on db: any Database) async throws -> DangerPost {
      try await makeDangerPost(by: user, in: try await makeDangerCategory(on: db), on: db)
    }

    // MARK: - POST /dangers/comments/post/:dangerPostID

    @Test("Commenting a danger post requires a token")
    func createWithoutToken() async throws {
      try await withAppIncludingDB { app in
        let post = try await makePost(by: try await makeUser(on: app.db), on: app.db)

        try await app.testing().test(
          .POST, "dangers/comments/post/\(post.requireID())",
          beforeRequest: { req in
            try req.content.encode(CreateDangerCommentDTO(content: "Nice"))
          },
          afterResponse: { res async throws in
            #expect(res.status == .unauthorized)
            #expect(try await DangerComment.query(on: app.db).count() == 0)
          })
      }
    }

    @Test("Commenting a danger post returns the post with my comment, trimmed")
    func create() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let post = try await makePost(by: user, on: app.db)

        try await app.testing().test(
          .POST, "dangers/comments/post/\(post.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: user)
            try req.content.encode(CreateDangerCommentDTO(content: "  Nice  "))
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let comments = try res.content.decode(GetDangerPostDTO.self).comments
            #expect(comments.map(\.content) == ["Nice"])
            #expect(comments.first?.user.id == user.id)
          })
      }
    }

    @Test("Commenting an unknown danger post returns 404")
    func createUnknownPost() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)

        try await app.testing().test(
          .POST, "dangers/comments/post/\(UUID())",
          beforeRequest: { req in
            try authorize(&req, as: user)
            try req.content.encode(CreateDangerCommentDTO(content: "Nice"))
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
          .POST, "dangers/comments/post/\(post.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: user)
            try req.content.encode(CreateDangerCommentDTO(content: ""))
          },
          afterResponse: { res async throws in
            #expect(res.status == .badRequest)
            #expect(try await DangerComment.query(on: app.db).count() == 0)
          })
      }
    }

    // MARK: - POST /dangers/comments/:id/like and /fav

    @Test("Liking a danger comment twice toggles the like on and off")
    func likeToggle() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let comment = try await makeDangerComment(by: user, on: try await makePost(by: user, on: app.db), on: app.db)

        try await app.testing().test(
          .POST, "dangers/comments/\(comment.requireID())/like",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let dto = try #require(try res.content.decode(GetDangerPostDTO.self).comments.first)
            #expect(dto.likeCount == 1)
            #expect(dto.likedByUser)
          })

        try await app.testing().test(
          .POST, "dangers/comments/\(comment.requireID())/like",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let dto = try #require(try res.content.decode(GetDangerPostDTO.self).comments.first)
            #expect(dto.likeCount == 0)
            #expect(!dto.likedByUser)
          })
      }
    }

    @Test("Faving a danger comment twice toggles the fav on and off")
    func favToggle() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let comment = try await makeDangerComment(by: user, on: try await makePost(by: user, on: app.db), on: app.db)

        try await app.testing().test(
          .POST, "dangers/comments/\(comment.requireID())/fav",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            #expect(try #require(try res.content.decode(GetDangerPostDTO.self).comments.first).favedByUser)
          })

        try await app.testing().test(
          .POST, "dangers/comments/\(comment.requireID())/fav",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            #expect(!(try #require(try res.content.decode(GetDangerPostDTO.self).comments.first).favedByUser))
          })
      }
    }

    @Test("Liking an unknown danger comment returns 404")
    func likeUnknownComment() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)

        try await app.testing().test(
          .POST, "dangers/comments/\(UUID())/like",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async in
            #expect(res.status == .notFound)
          })
      }
    }

    @Test("Faving an unknown danger comment returns 404")
    func favUnknownComment() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)

        try await app.testing().test(
          .POST, "dangers/comments/\(UUID())/fav",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async in
            #expect(res.status == .notFound)
          })
      }
    }

    // MARK: - PATCH /dangers/comments/:id

    @Test("Patching a danger comment as a moderator updates it, trimmed")
    func patchAsModerator() async throws {
      try await withAppIncludingDB { app in
        let moderator = try await makeUser(adminRights: 1, on: app.db)
        let author = try await makeUser(on: app.db)
        let comment = try await makeDangerComment(content: "Original", by: author, on: try await makePost(by: author, on: app.db), on: app.db)

        try await app.testing().test(
          .PATCH, "dangers/comments/\(comment.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: moderator)
            try req.content.encode(PatchDangerCommentDTO(content: "  Edited  "))
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            #expect(try res.content.decode(GetDangerCommentDTO.self).content == "Edited")
            #expect(try await DangerComment.find(comment.id, on: app.db)?.content == "Edited")
          })
      }
    }

    @Test("Patching a danger comment ignores fields that belong to posts")
    func patchIgnoresPostFields() async throws {
      try await withAppIncludingDB { app in
        let moderator = try await makeUser(adminRights: 1, on: app.db)
        let comment = try await makeDangerComment(content: "Original", by: moderator, on: try await makePost(by: moderator, on: app.db), on: app.db)

        try await app.testing().test(
          .PATCH, "dangers/comments/\(comment.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: moderator)
            req.headers.contentType = .json
            req.body = ByteBuffer(string: #"{"content": "Edited", "latitude": 91}"#)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            #expect(try await DangerComment.find(comment.id, on: app.db)?.content == "Edited")
          })
      }
    }

    @Test("Patching my own danger comment as a regular user is forbidden")
    func patchAsAuthor() async throws {
      try await withAppIncludingDB { app in
        let author = try await makeUser(on: app.db)
        let comment = try await makeDangerComment(content: "Original", by: author, on: try await makePost(by: author, on: app.db), on: app.db)

        try await app.testing().test(
          .PATCH, "dangers/comments/\(comment.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: author)
            try req.content.encode(PatchDangerCommentDTO(content: "Edited"))
          },
          afterResponse: { res async throws in
            #expect(res.status == .forbidden)
            #expect(try await DangerComment.find(comment.id, on: app.db)?.content == "Original")
          })
      }
    }

    @Test("Patching a danger comment with empty content fails validation")
    func patchEmptyContent() async throws {
      try await withAppIncludingDB { app in
        let moderator = try await makeUser(adminRights: 1, on: app.db)
        let comment = try await makeDangerComment(content: "Original", by: moderator, on: try await makePost(by: moderator, on: app.db), on: app.db)

        try await app.testing().test(
          .PATCH, "dangers/comments/\(comment.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: moderator)
            try req.content.encode(PatchDangerCommentDTO(content: ""))
          },
          afterResponse: { res async throws in
            #expect(res.status == .badRequest)
            #expect(try await DangerComment.find(comment.id, on: app.db)?.content == "Original")
          })
      }
    }

    @Test("Patching an unknown danger comment returns 404")
    func patchUnknownID() async throws {
      try await withAppIncludingDB { app in
        let moderator = try await makeUser(adminRights: 1, on: app.db)

        try await app.testing().test(
          .PATCH, "dangers/comments/\(UUID())",
          beforeRequest: { req in
            try authorize(&req, as: moderator)
            try req.content.encode(PatchDangerCommentDTO(content: "Edited"))
          },
          afterResponse: { res async in
            #expect(res.status == .notFound)
          })
      }
    }

    // MARK: - DELETE /dangers/comments/:id

    @Test("Deleting a danger comment as a moderator removes it")
    func deleteAsModerator() async throws {
      try await withAppIncludingDB { app in
        let moderator = try await makeUser(adminRights: 1, on: app.db)
        let author = try await makeUser(on: app.db)
        let comment = try await makeDangerComment(by: author, on: try await makePost(by: author, on: app.db), on: app.db)

        try await app.testing().test(
          .DELETE, "dangers/comments/\(comment.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: moderator)
          },
          afterResponse: { res async throws in
            #expect(res.status == .noContent)
            #expect(try await DangerComment.find(comment.id, on: app.db) == nil)
          })
      }
    }

    @Test("Deleting my own danger comment as a regular user is forbidden")
    func deleteAsAuthor() async throws {
      try await withAppIncludingDB { app in
        let author = try await makeUser(on: app.db)
        let comment = try await makeDangerComment(by: author, on: try await makePost(by: author, on: app.db), on: app.db)

        try await app.testing().test(
          .DELETE, "dangers/comments/\(comment.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: author)
          },
          afterResponse: { res async throws in
            #expect(res.status == .forbidden)
            #expect(try await DangerComment.find(comment.id, on: app.db) != nil)
          })
      }
    }

    @Test("Deleting an unknown danger comment returns 404")
    func deleteUnknownID() async throws {
      try await withAppIncludingDB { app in
        let moderator = try await makeUser(adminRights: 1, on: app.db)

        try await app.testing().test(
          .DELETE, "dangers/comments/\(UUID())",
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
