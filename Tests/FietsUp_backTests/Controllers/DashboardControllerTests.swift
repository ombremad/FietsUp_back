@testable import FietsUp_back
import Fluent
import VaporTesting
import Testing

extension DatabaseTests {
  @Suite("Dashboard Controller Tests with DB", .serialized)
  struct DashboardControllerTests {
    @Test("Getting my favorites requires a token")
    func favoritesWithoutToken() async throws {
      try await withAppIncludingDB { app in
        try await app.testing().test(.GET, "dashboard/favorites") { res async in
          #expect(res.status == .unauthorized)
        }
      }
    }

    @Test("A new user has no favorites")
    func favoritesEmpty() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)

        try await app.testing().test(
          .GET, "dashboard/favorites",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let dto = try res.content.decode(GetAllFavoritesDTO.self)
            #expect(dto.forumPosts.isEmpty)
            #expect(dto.forumComments.isEmpty)
            #expect(dto.dangerPosts.isEmpty)
            #expect(dto.dangerComments.isEmpty)
          })
      }
    }

    @Test("Getting my favorites returns every kind I faved, and nobody else's")
    func favoritesOnlyMine() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let other = try await makeUser(on: app.db)
        let forumPost = try await makeForumPost(by: other, in: try await makeForumCategory(on: app.db), on: app.db)
        let forumComment = try await makeForumComment(by: other, on: forumPost, on: app.db)
        let dangerPost = try await makeDangerPost(by: other, in: try await makeDangerCategory(on: app.db), on: app.db)
        let dangerComment = try await makeDangerComment(by: other, on: dangerPost, on: app.db)
        let otherPost = try await makeForumPost(title: "Not mine", by: other, in: try await makeForumCategory(name: "Other", on: app.db), on: app.db)
        try await ForumPostFav(userID: user.requireID(), forumPostID: forumPost.requireID()).save(on: app.db)
        try await ForumCommentFav(userID: user.requireID(), forumCommentID: forumComment.requireID()).save(on: app.db)
        try await DangerPostFav(userID: user.requireID(), dangerPostID: dangerPost.requireID()).save(on: app.db)
        try await DangerCommentFav(userID: user.requireID(), dangerCommentID: dangerComment.requireID()).save(on: app.db)
        try await ForumPostFav(userID: other.requireID(), forumPostID: otherPost.requireID()).save(on: app.db)

        try await app.testing().test(
          .GET, "dashboard/favorites",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let dto = try res.content.decode(GetAllFavoritesDTO.self)
            #expect(dto.forumPosts.map(\.id) == [forumPost.id])
            #expect(dto.forumComments.map(\.id) == [forumComment.id])
            #expect(dto.dangerPosts.map(\.id) == [dangerPost.id])
            #expect(dto.dangerComments.map(\.id) == [dangerComment.id])
          })
      }
    }

    @Test("My favorites are listed newest first")
    func favoritesNewestFirst() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let category = try await makeForumCategory(on: app.db)
        let older = try await makeForumPost(title: "Older", by: user, in: category, on: app.db)
        let newer = try await makeForumPost(title: "Newer", by: user, in: category, on: app.db)
        try await setDate("creation_date", in: "forum_posts", id: older.requireID(), secondsAgo: 120, on: app.db)
        try await setDate("creation_date", in: "forum_posts", id: newer.requireID(), secondsAgo: 60, on: app.db)
        try await ForumPostFav(userID: user.requireID(), forumPostID: older.requireID()).save(on: app.db)
        try await ForumPostFav(userID: user.requireID(), forumPostID: newer.requireID()).save(on: app.db)

        try await app.testing().test(
          .GET, "dashboard/favorites",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            #expect(try res.content.decode(GetAllFavoritesDTO.self).forumPosts.map(\.title) == ["Newer", "Older"])
          })
      }
    }

    @Test("Un-faving an item removes it from my favorites")
    func favoritesAfterUnfav() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let post = try await makeForumPost(by: user, in: try await makeForumCategory(on: app.db), on: app.db)
        try await ForumPostFav(userID: user.requireID(), forumPostID: post.requireID()).save(on: app.db)

        try await app.testing().test(
          .POST, "forum/posts/\(post.requireID())/fav",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async in
            #expect(res.status == .ok)
          })

        try await app.testing().test(
          .GET, "dashboard/favorites",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            #expect(try res.content.decode(GetAllFavoritesDTO.self).forumPosts.isEmpty)
          })
      }
    }

    @Test("My favorites show each author's selected cycle")
    func favoritesAuthorCycle() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let author = try await makeUser(on: app.db)
        let cycleType = try await selectCycle(for: author, on: app.db)
        let post = try await makeForumPost(by: author, in: try await makeForumCategory(on: app.db), on: app.db)
        try await ForumPostFav(userID: user.requireID(), forumPostID: post.requireID()).save(on: app.db)

        try await app.testing().test(
          .GET, "dashboard/favorites",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            #expect(try res.content.decode(GetAllFavoritesDTO.self).forumPosts.first?.user.cycleType?.id == cycleType.id)
          })
      }
    }
  }
}
