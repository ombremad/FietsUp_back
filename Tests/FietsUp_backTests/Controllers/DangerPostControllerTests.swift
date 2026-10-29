@testable import FietsUp_back
import Fluent
import VaporTesting
import Testing

extension DatabaseTests {
  @Suite("Danger Post Controller Tests with DB", .serialized)
  struct DangerPostControllerTests {
    // Around Paris: 0.045° of latitude ≈ 5 km, 0.09° ≈ 10 km, 0.18° ≈ 20 km.
    private let latitude = 48.8566
    private let longitude = 2.3522

    private var nearQuery: String { "dangers/posts/near?latitude=\(latitude)&longitude=\(longitude)" }

    // MARK: - POST /dangers/posts/category/:dangerCategoryID

    @Test("Creating a danger post requires a token")
    func createWithoutToken() async throws {
      try await withAppIncludingDB { app in
        let category = try await makeDangerCategory(on: app.db)

        try await app.testing().test(
          .POST, "dangers/posts/category/\(category.requireID())",
          beforeRequest: { req in
            try req.content.encode(CreateDangerPostDTO(title: "Pothole", content: "Big", latitude: latitude, longitude: longitude))
          },
          afterResponse: { res async throws in
            #expect(res.status == .unauthorized)
            #expect(try await DangerPost.query(on: app.db).count() == 0)
          })
      }
    }

    @Test("Creating a danger post saves it, trimmed, with its location and category")
    func create() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let category = try await makeDangerCategory(name: "Pothole", on: app.db)

        try await app.testing().test(
          .POST, "dangers/posts/category/\(category.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: user)
            try req.content.encode(CreateDangerPostDTO(title: "  Hole  ", content: "  Big  ", latitude: latitude, longitude: longitude))
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let dto = try res.content.decode(GetDangerPostDTO.self)
            #expect(dto.title == "Hole")
            #expect(dto.content == "Big")
            #expect(dto.latitude == latitude)
            #expect(dto.longitude == longitude)
            #expect(dto.dangerCategory.id == category.id)
            #expect(dto.user.id == user.id)
            #expect(dto.likeCount == 0)
            #expect(dto.comments.isEmpty)
          })
      }
    }

    @Test("Creating a danger post in an unknown category returns 404")
    func createUnknownCategory() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)

        try await app.testing().test(
          .POST, "dangers/posts/category/\(UUID())",
          beforeRequest: { req in
            try authorize(&req, as: user)
            try req.content.encode(CreateDangerPostDTO(title: "Hole", content: "Big", latitude: latitude, longitude: longitude))
          },
          afterResponse: { res async in
            #expect(res.status == .notFound)
          })
      }
    }

    @Test(
      "Creating a danger post with out-of-range coordinates fails validation",
      arguments: [(91.0, 2.0), (-91.0, 2.0), (48.0, 181.0), (48.0, -181.0)])
    func createInvalidCoordinates(latitude: Double, longitude: Double) async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let category = try await makeDangerCategory(on: app.db)

        try await app.testing().test(
          .POST, "dangers/posts/category/\(category.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: user)
            try req.content.encode(CreateDangerPostDTO(title: "Hole", content: "Big", latitude: latitude, longitude: longitude))
          },
          afterResponse: { res async throws in
            #expect(res.status == .badRequest)
            #expect(try await DangerPost.query(on: app.db).count() == 0)
          })
      }
    }

    @Test("Creating a danger post shows my selected cycle as its author")
    func createAuthorCycle() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let cycleType = try await selectCycle(for: user, on: app.db)
        let category = try await makeDangerCategory(on: app.db)

        try await app.testing().test(
          .POST, "dangers/posts/category/\(category.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: user)
            try req.content.encode(CreateDangerPostDTO(title: "Hole", content: "Big", latitude: latitude, longitude: longitude))
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            #expect(try res.content.decode(GetDangerPostDTO.self).user.cycleType?.id == cycleType.id)
          })
      }
    }

    // MARK: - POST /dangers/posts/:id/like and /fav

    @Test("Liking a danger post twice toggles the like on and off")
    func likeToggle() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let post = try await makeDangerPost(by: user, in: try await makeDangerCategory(on: app.db), on: app.db)

        try await app.testing().test(
          .POST, "dangers/posts/\(post.requireID())/like",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let dto = try res.content.decode(GetDangerPostDTO.self)
            #expect(dto.likeCount == 1)
            #expect(dto.likedByUser)
          })

        try await app.testing().test(
          .POST, "dangers/posts/\(post.requireID())/like",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let dto = try res.content.decode(GetDangerPostDTO.self)
            #expect(dto.likeCount == 0)
            #expect(!dto.likedByUser)
          })
      }
    }

    @Test("Faving a danger post twice toggles the fav on and off")
    func favToggle() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let post = try await makeDangerPost(by: user, in: try await makeDangerCategory(on: app.db), on: app.db)

        try await app.testing().test(
          .POST, "dangers/posts/\(post.requireID())/fav",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            #expect(try res.content.decode(GetDangerPostDTO.self).favedByUser)
          })

        try await app.testing().test(
          .POST, "dangers/posts/\(post.requireID())/fav",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            #expect(!(try res.content.decode(GetDangerPostDTO.self).favedByUser))
          })
      }
    }

    @Test("Liking an unknown danger post returns 404")
    func likeUnknownPost() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)

        try await app.testing().test(
          .POST, "dangers/posts/\(UUID())/like",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async in
            #expect(res.status == .notFound)
          })
      }
    }

    @Test("Faving an unknown danger post returns 404")
    func favUnknownPost() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)

        try await app.testing().test(
          .POST, "dangers/posts/\(UUID())/fav",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async in
            #expect(res.status == .notFound)
          })
      }
    }

    // MARK: - GET /dangers/posts

    @Test("Listing danger posts returns them newest first with comment counts")
    func getAll() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let category = try await makeDangerCategory(on: app.db)
        let old = try await makeDangerPost(title: "Old", by: user, in: category, on: app.db)
        let new = try await makeDangerPost(title: "New", by: user, in: category, on: app.db)
        try await makeDangerComment(by: user, on: old, on: app.db)
        try await setDate("creation_date", in: "danger_posts", id: old.requireID(), secondsAgo: 3600, on: app.db)
        try await setDate("creation_date", in: "danger_posts", id: new.requireID(), secondsAgo: 0, on: app.db)

        try await app.testing().test(
          .GET, "dangers/posts",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let dtos = try res.content.decode([GetDangerPostWithCountsDTO].self)
            #expect(dtos.map(\.title) == ["New", "Old"])
            #expect(dtos.map(\.totalComments) == [0, 1])
          })
      }
    }

    @Test("Listing danger posts shows each author's selected cycle")
    func getAllAuthorCycle() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let cycleType = try await selectCycle(for: user, on: app.db)
        try await makeDangerPost(by: user, in: try await makeDangerCategory(on: app.db), on: app.db)

        try await app.testing().test(
          .GET, "dangers/posts",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            #expect(try res.content.decode([GetDangerPostWithCountsDTO].self).first?.user.cycleType?.id == cycleType.id)
          })
      }
    }

    // MARK: - GET /dangers/posts/near

    @Test("Nearby danger posts are those within 15 km, closest first")
    func getNearest() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let category = try await makeDangerCategory(on: app.db)
        try await makeDangerPost(title: "10 km", latitude: latitude + 0.09, longitude: longitude, by: user, in: category, on: app.db)
        try await makeDangerPost(title: "20 km", latitude: latitude + 0.18, longitude: longitude, by: user, in: category, on: app.db)
        try await makeDangerPost(title: "5 km", latitude: latitude + 0.045, longitude: longitude, by: user, in: category, on: app.db)

        try await app.testing().test(
          .GET, nearQuery,
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            #expect(try res.content.decode([GetDangerPostWithCountsDTO].self).map(\.title) == ["5 km", "10 km"])
          })
      }
    }

    @Test("Nearby danger posts exclude posts inactive for more than 7 days")
    func getNearestExcludesStalePosts() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let category = try await makeDangerCategory(on: app.db)
        let stale = try await makeDangerPost(title: "Stale", by: user, in: category, on: app.db)
        try await makeDangerPost(title: "Fresh", by: user, in: category, on: app.db)
        try await age(stale, byDays: 8, on: app.db)

        try await app.testing().test(
          .GET, nearQuery,
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            #expect(try res.content.decode([GetDangerPostWithCountsDTO].self).map(\.title) == ["Fresh"])
          })
      }
    }

    @Test("Nearby danger posts include old posts with a recent comment")
    func getNearestIncludesRevivedPosts() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let post = try await makeDangerPost(title: "Revived", by: user, in: try await makeDangerCategory(on: app.db), on: app.db)
        try await age(post, byDays: 8, on: app.db)
        try await makeDangerComment(by: user, on: post, on: app.db)

        try await app.testing().test(
          .GET, nearQuery,
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            #expect(try res.content.decode([GetDangerPostWithCountsDTO].self).map(\.title) == ["Revived"])
          })
      }
    }

    @Test(
      "Nearby danger posts need valid coordinates",
      arguments: ["dangers/posts/near", "dangers/posts/near?latitude=91&longitude=2", "dangers/posts/near?latitude=48"])
    func getNearestInvalidQuery(url: String) async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)

        try await app.testing().test(
          .GET, url,
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async in
            #expect(res.status == .badRequest)
          })
      }
    }

    @Test("Nearby danger posts show each author's selected cycle")
    func getNearestAuthorCycle() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let cycleType = try await selectCycle(for: user, on: app.db)
        try await makeDangerPost(by: user, in: try await makeDangerCategory(on: app.db), on: app.db)

        try await app.testing().test(
          .GET, nearQuery,
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            #expect(try res.content.decode([GetDangerPostWithCountsDTO].self).first?.user.cycleType?.id == cycleType.id)
          })
      }
    }

    // MARK: - GET /dangers/posts/:id

    @Test("Getting a danger post lists its comments newest first")
    func getByID() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let post = try await makeDangerPost(by: user, in: try await makeDangerCategory(on: app.db), on: app.db)
        let older = try await makeDangerComment(content: "Older", by: user, on: post, on: app.db)
        let newer = try await makeDangerComment(content: "Newer", by: user, on: post, on: app.db)
        try await setDate("creation_date", in: "danger_comments", id: older.requireID(), secondsAgo: 120, on: app.db)
        try await setDate("creation_date", in: "danger_comments", id: newer.requireID(), secondsAgo: 60, on: app.db)

        try await app.testing().test(
          .GET, "dangers/posts/\(post.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            #expect(try res.content.decode(GetDangerPostDTO.self).comments.map(\.content) == ["Newer", "Older"])
          })
      }
    }

    @Test("Getting an unknown danger post returns 404")
    func getByUnknownID() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)

        try await app.testing().test(
          .GET, "dangers/posts/\(UUID())",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async in
            #expect(res.status == .notFound)
          })
      }
    }

    // MARK: - PATCH /dangers/posts/:id

    @Test("Moving a danger post as a moderator changes where it's found nearby")
    func patchLocationAsModerator() async throws {
      try await withAppIncludingDB { app in
        let moderator = try await makeUser(adminRights: 1, on: app.db)
        let post = try await makeDangerPost(title: "Moved", latitude: latitude + 1, longitude: longitude, by: moderator, in: try await makeDangerCategory(on: app.db), on: app.db)

        try await app.testing().test(
          .PATCH, "dangers/posts/\(post.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: moderator)
            try req.content.encode(PatchDangerPostDTO(latitude: latitude, longitude: longitude))
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            #expect(try res.content.decode(GetDangerPostDTO.self).latitude == latitude)
          })

        try await app.testing().test(
          .GET, nearQuery,
          beforeRequest: { req in
            try authorize(&req, as: moderator)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            #expect(try res.content.decode([GetDangerPostWithCountsDTO].self).map(\.title) == ["Moved"])
          })
      }
    }

    @Test("Patching my own danger post as a regular user is forbidden")
    func patchAsAuthor() async throws {
      try await withAppIncludingDB { app in
        let author = try await makeUser(on: app.db)
        let post = try await makeDangerPost(title: "Hole", by: author, in: try await makeDangerCategory(on: app.db), on: app.db)

        try await app.testing().test(
          .PATCH, "dangers/posts/\(post.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: author)
            try req.content.encode(PatchDangerPostDTO(title: "Edited"))
          },
          afterResponse: { res async throws in
            #expect(res.status == .forbidden)
            #expect(try await DangerPost.find(post.id, on: app.db)?.title == "Hole")
          })
      }
    }

    @Test("Patching a danger post with an out-of-range latitude fails validation")
    func patchInvalidLatitude() async throws {
      try await withAppIncludingDB { app in
        let moderator = try await makeUser(adminRights: 1, on: app.db)
        let post = try await makeDangerPost(latitude: latitude, by: moderator, in: try await makeDangerCategory(on: app.db), on: app.db)

        try await app.testing().test(
          .PATCH, "dangers/posts/\(post.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: moderator)
            try req.content.encode(PatchDangerPostDTO(latitude: 91))
          },
          afterResponse: { res async throws in
            #expect(res.status == .badRequest)
            #expect(try await DangerPost.find(post.id, on: app.db)?.latitude == latitude)
          })
      }
    }

    @Test("Patching an unknown danger post returns 404")
    func patchUnknownID() async throws {
      try await withAppIncludingDB { app in
        let moderator = try await makeUser(adminRights: 1, on: app.db)

        try await app.testing().test(
          .PATCH, "dangers/posts/\(UUID())",
          beforeRequest: { req in
            try authorize(&req, as: moderator)
            try req.content.encode(PatchDangerPostDTO(title: "Edited"))
          },
          afterResponse: { res async in
            #expect(res.status == .notFound)
          })
      }
    }

    // MARK: - DELETE /dangers/posts/:id

    @Test("Deleting a danger post as a moderator deletes its comments too")
    func deleteAsModerator() async throws {
      try await withAppIncludingDB { app in
        let moderator = try await makeUser(adminRights: 1, on: app.db)
        let post = try await makeDangerPost(by: moderator, in: try await makeDangerCategory(on: app.db), on: app.db)
        try await makeDangerComment(by: moderator, on: post, on: app.db)

        try await app.testing().test(
          .DELETE, "dangers/posts/\(post.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: moderator)
          },
          afterResponse: { res async throws in
            #expect(res.status == .noContent)
            #expect(try await DangerPost.find(post.id, on: app.db) == nil)
            #expect(try await DangerComment.query(on: app.db).count() == 0)
          })
      }
    }

    @Test("Deleting my own danger post as a regular user is forbidden")
    func deleteAsAuthor() async throws {
      try await withAppIncludingDB { app in
        let author = try await makeUser(on: app.db)
        let post = try await makeDangerPost(by: author, in: try await makeDangerCategory(on: app.db), on: app.db)

        try await app.testing().test(
          .DELETE, "dangers/posts/\(post.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: author)
          },
          afterResponse: { res async throws in
            #expect(res.status == .forbidden)
            #expect(try await DangerPost.find(post.id, on: app.db) != nil)
          })
      }
    }

    @Test("Deleting an unknown danger post returns 404")
    func deleteUnknownID() async throws {
      try await withAppIncludingDB { app in
        let moderator = try await makeUser(adminRights: 1, on: app.db)

        try await app.testing().test(
          .DELETE, "dangers/posts/\(UUID())",
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
