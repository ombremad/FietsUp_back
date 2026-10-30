@testable import FietsUp_back
import Fluent
import VaporTesting
import Testing

extension DatabaseTests {
  @Suite("User Controller Tests with DB", .serialized)
  struct UserControllerTests {
    private func makeCycleType(on db: any Database) async throws -> CycleType {
      let cycleType = CycleType()
      cycleType.name = "Gazelle"
      cycleType.fileLink = "gazelle.png"
      try await cycleType.save(on: db)
      return cycleType
    }

    // MARK: - POST /users/signup

    @Test("Signing up creates a user, hashes the password and returns a working token")
    func signup() async throws {
      try await withAppIncludingDB { app in
        let dto = CreateUserDTO(
          firstName: "  Anne  ", lastName: " Ferret ", nickname: "anne",
          email: "anne@example.com", password: testPassword, bio: nil)
        var authToken = ""

        try await app.testing().test(
          .POST, "users/signup",
          beforeRequest: { req in
            try req.content.encode(dto)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let auth = try res.content.decode(GetAuthDTO.self)
            #expect(auth.user.firstName == "Anne")
            #expect(auth.user.lastName == "Ferret")
            #expect(auth.user.email == "anne@example.com")
            #expect(auth.user.adminRights == 0)
            authToken = auth.token

            let stored = try #require(
              try await User.query(on: app.db).filter(\.$email == "anne@example.com").first())
            #expect(stored.password != testPassword)
            #expect(try Bcrypt.verify(testPassword, created: stored.password))
          })

        try await app.testing().test(
          .GET, "users/me",
          beforeRequest: { req in
            req.headers.bearerAuthorization = BearerAuthorization(token: authToken)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            #expect(try res.content.decode(GetUserDTO.self).nickname == "anne")
          })
      }
    }

    @Test("Signing up with a weak password fails validation")
    func signupWeakPassword() async throws {
      try await withAppIncludingDB { app in
        let dto = CreateUserDTO(
          firstName: "Anne", lastName: "Ferret", nickname: "anne",
          email: "anne@example.com", password: "password", bio: nil)

        try await app.testing().test(
          .POST, "users/signup",
          beforeRequest: { req in
            try req.content.encode(dto)
          },
          afterResponse: { res async throws in
            #expect(res.status == .badRequest)
            #expect(try await User.query(on: app.db).count() == 0)
          })
      }
    }

    @Test("Signing up with an invalid email fails validation")
    func signupInvalidEmail() async throws {
      try await withAppIncludingDB { app in
        let dto = CreateUserDTO(
          firstName: "Anne", lastName: "Ferret", nickname: "anne",
          email: "not-an-email", password: testPassword, bio: nil)

        try await app.testing().test(
          .POST, "users/signup",
          beforeRequest: { req in
            try req.content.encode(dto)
          },
          afterResponse: { res async throws in
            #expect(res.status == .badRequest)
          })
      }
    }

    @Test("Signing up with a non-ASCII nickname fails validation")
    func signupNonASCIINickname() async throws {
      try await withAppIncludingDB { app in
        let dto = CreateUserDTO(
          firstName: "Anne", lastName: "Ferret", nickname: "anné",
          email: "anne@example.com", password: testPassword, bio: nil)

        try await app.testing().test(
          .POST, "users/signup",
          beforeRequest: { req in
            try req.content.encode(dto)
          },
          afterResponse: { res async throws in
            #expect(res.status == .badRequest)
          })
      }
    }

    @Test("Signing up with an email already in use returns 409")
    func signupDuplicateEmail() async throws {
      try await withAppIncludingDB { app in
        try await makeUser(email: "taken@example.com", on: app.db)
        let dto = CreateUserDTO(
          firstName: "Anne", lastName: "Ferret", nickname: "anne",
          email: "taken@example.com", password: testPassword, bio: nil)

        try await app.testing().test(
          .POST, "users/signup",
          beforeRequest: { req in
            try req.content.encode(dto)
          },
          afterResponse: { res async in
            #expect(res.status == .conflict)
          })
      }
    }

    @Test("Signing up with a nickname already in use returns 409")
    func signupDuplicateNickname() async throws {
      try await withAppIncludingDB { app in
        try await makeUser(nickname: "taken", on: app.db)
        let dto = CreateUserDTO(
          firstName: "Anne", lastName: "Ferret", nickname: "taken",
          email: "anne@example.com", password: testPassword, bio: nil)

        try await app.testing().test(
          .POST, "users/signup",
          beforeRequest: { req in
            try req.content.encode(dto)
          },
          afterResponse: { res async in
            #expect(res.status == .conflict)
          })
      }
    }

    // MARK: - POST /users/login

    @Test("Logging in with correct credentials returns a token and the user")
    func login() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(email: "anne@example.com", on: app.db)

        try await app.testing().test(
          .POST, "users/login",
          beforeRequest: { req in
            try req.content.encode(LoginUserDTO(email: "anne@example.com", password: testPassword))
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let auth = try res.content.decode(GetAuthDTO.self)
            #expect(auth.user.id == user.id)
            #expect(!auth.token.isEmpty)
          })
      }
    }

    @Test("Logging in with a wrong password returns 401")
    func loginWrongPassword() async throws {
      try await withAppIncludingDB { app in
        try await makeUser(email: "anne@example.com", on: app.db)

        try await app.testing().test(
          .POST, "users/login",
          beforeRequest: { req in
            try req.content.encode(LoginUserDTO(email: "anne@example.com", password: "Wr0ngPass!"))
          },
          afterResponse: { res async in
            #expect(res.status == .unauthorized)
          })
      }
    }

    @Test("Logging in with an unknown email returns 401")
    func loginUnknownEmail() async throws {
      try await withAppIncludingDB { app in
        try await app.testing().test(
          .POST, "users/login",
          beforeRequest: { req in
            try req.content.encode(LoginUserDTO(email: "nobody@example.com", password: testPassword))
          },
          afterResponse: { res async in
            #expect(res.status == .unauthorized)
          })
      }
    }

    @Test("Logging in while banned returns 401")
    func loginBanned() async throws {
      try await withAppIncludingDB { app in
        try await makeUser(
          email: "anne@example.com", banEndDate: Date().addingTimeInterval(3600), on: app.db)

        try await app.testing().test(
          .POST, "users/login",
          beforeRequest: { req in
            try req.content.encode(LoginUserDTO(email: "anne@example.com", password: testPassword))
          },
          afterResponse: { res async in
            #expect(res.status == .unauthorized)
          })
      }
    }

    @Test("Logging in after a ban has ended succeeds")
    func loginBanEnded() async throws {
      try await withAppIncludingDB { app in
        try await makeUser(
          email: "anne@example.com", banEndDate: Date().addingTimeInterval(-3600), on: app.db)

        try await app.testing().test(
          .POST, "users/login",
          beforeRequest: { req in
            try req.content.encode(LoginUserDTO(email: "anne@example.com", password: testPassword))
          },
          afterResponse: { res async in
            #expect(res.status == .ok)
          })
      }
    }

    // MARK: - GET /users

    @Test("Listing users requires a token")
    func getAllWithoutToken() async throws {
      try await withAppIncludingDB { app in
        try await app.testing().test(.GET, "users") { res async in
          #expect(res.status == .unauthorized)
        }
      }
    }

    @Test("Listing users as a moderator is forbidden")
    func getAllAsModerator() async throws {
      try await withAppIncludingDB { app in
        let moderator = try await makeUser(adminRights: 1, on: app.db)

        try await app.testing().test(
          .GET, "users",
          beforeRequest: { req in
            try authorize(&req, as: moderator)
          },
          afterResponse: { res async in
            #expect(res.status == .forbidden)
          })
      }
    }

    @Test("Listing users as an admin returns a page sorted by email")
    func getAllAsAdmin() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, email: "admin@example.com", on: app.db)
        for email in ["c@example.com", "a@example.com", "b@example.com"] {
          try await makeUser(email: email, on: app.db)
        }

        try await app.testing().test(
          .GET, "users",
          beforeRequest: { req in
            try authorize(&req, as: admin)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let page = try res.content.decode(Page<GetUserDTO>.self)
            #expect(
              page.items.map(\.email)
                == ["a@example.com", "admin@example.com", "b@example.com", "c@example.com"])
            #expect(page.metadata.total == 4)
          })
      }
    }

    @Test("Listing users honours page and per")
    func getAllPaginated() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, email: "admin@example.com", on: app.db)
        for email in ["c@example.com", "a@example.com", "b@example.com"] {
          try await makeUser(email: email, on: app.db)
        }

        try await app.testing().test(
          .GET, "users?page=2&per=2",
          beforeRequest: { req in
            try authorize(&req, as: admin)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let page = try res.content.decode(Page<GetUserDTO>.self)
            #expect(page.items.map(\.email) == ["b@example.com", "c@example.com"])
            #expect(page.metadata.page == 2)
            #expect(page.metadata.per == 2)
          })
      }
    }

    @Test("Listing users with more than 25 per page fails validation")
    func getAllPerTooLarge() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)

        try await app.testing().test(
          .GET, "users?per=26",
          beforeRequest: { req in
            try authorize(&req, as: admin)
          },
          afterResponse: { res async in
            #expect(res.status == .badRequest)
          })
      }
    }

    // MARK: - GET /users/:userID

    @Test("Finding a user by id as an admin returns it")
    func getByID() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)
        let user = try await makeUser(email: "anne@example.com", on: app.db)

        try await app.testing().test(
          .GET, "users/\(user.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: admin)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let dto = try res.content.decode(GetUserDTO.self)
            #expect(dto.id == user.id)
            #expect(dto.email == "anne@example.com")
          })
      }
    }

    @Test("Finding an unknown user returns 404")
    func getByUnknownID() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)

        try await app.testing().test(
          .GET, "users/\(UUID())",
          beforeRequest: { req in
            try authorize(&req, as: admin)
          },
          afterResponse: { res async in
            #expect(res.status == .notFound)
          })
      }
    }

    @Test("Finding a user with a malformed id returns 422")
    func getByMalformedID() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)

        try await app.testing().test(
          .GET, "users/not-a-uuid",
          beforeRequest: { req in
            try authorize(&req, as: admin)
          },
          afterResponse: { res async in
            #expect(res.status == .unprocessableEntity)
          })
      }
    }

    // MARK: - PATCH /users/:userID

    @Test("Patching a user as an admin updates and saves every field")
    func patchByID() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)
        let user = try await makeUser(on: app.db)
        let dto = PatchUserAdminDTO(
          email: "new@example.com", nickname: "newnick", firstName: " New ",
          lastName: " Name ", bio: "Hello", adminRights: 1)

        try await app.testing().test(
          .PATCH, "users/\(user.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(dto)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let stored = try #require(try await User.find(user.id, on: app.db))
            #expect(stored.email == "new@example.com")
            #expect(stored.nickname == "newnick")
            #expect(stored.firstName == "New")
            #expect(stored.lastName == "Name")
            #expect(stored.bio == "Hello")
            #expect(stored.adminRights == 1)
          })
      }
    }

    @Test("Patching a user with admin rights above 2 fails validation")
    func patchByIDInvalidAdminRights() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)
        let user = try await makeUser(on: app.db)

        try await app.testing().test(
          .PATCH, "users/\(user.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(PatchUserAdminDTO(adminRights: 3))
          },
          afterResponse: { res async throws in
            #expect(res.status == .badRequest)
            #expect(try await User.find(user.id, on: app.db)?.adminRights == 0)
          })
      }
    }

    @Test("Patching a user as a moderator is forbidden")
    func patchByIDAsModerator() async throws {
      try await withAppIncludingDB { app in
        let moderator = try await makeUser(adminRights: 1, on: app.db)
        let user = try await makeUser(on: app.db)

        try await app.testing().test(
          .PATCH, "users/\(user.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: moderator)
            try req.content.encode(PatchUserAdminDTO(adminRights: 2))
          },
          afterResponse: { res async throws in
            #expect(res.status == .forbidden)
            #expect(try await User.find(user.id, on: app.db)?.adminRights == 0)
          })
      }
    }

    @Test("Patching an unknown user returns 404")
    func patchByUnknownID() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)

        try await app.testing().test(
          .PATCH, "users/\(UUID())",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(PatchUserAdminDTO(nickname: "newnick"))
          },
          afterResponse: { res async in
            #expect(res.status == .notFound)
          })
      }
    }

    @Test("Patching a user with an email already in use returns 409")
    func patchByIDDuplicateEmail() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)
        try await makeUser(email: "taken@example.com", on: app.db)
        let user = try await makeUser(on: app.db)

        try await app.testing().test(
          .PATCH, "users/\(user.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: admin)
            try req.content.encode(PatchUserAdminDTO(email: "taken@example.com"))
          },
          afterResponse: { res async in
            #expect(res.status == .conflict)
          })
      }
    }

    // MARK: - DELETE /users/:userID

    @Test("Deleting a user as an admin removes it")
    func deleteByID() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)
        let user = try await makeUser(on: app.db)

        try await app.testing().test(
          .DELETE, "users/\(user.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: admin)
          },
          afterResponse: { res async throws in
            #expect(res.status == .noContent)
            #expect(try await User.find(user.id, on: app.db) == nil)
          })
      }
    }

    @Test("Deleting a user as a moderator is forbidden")
    func deleteByIDAsModerator() async throws {
      try await withAppIncludingDB { app in
        let moderator = try await makeUser(adminRights: 1, on: app.db)
        let user = try await makeUser(on: app.db)

        try await app.testing().test(
          .DELETE, "users/\(user.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: moderator)
          },
          afterResponse: { res async throws in
            #expect(res.status == .forbidden)
            #expect(try await User.find(user.id, on: app.db) != nil)
          })
      }
    }

    @Test("Deleting an unknown user returns 404")
    func deleteByUnknownID() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)

        try await app.testing().test(
          .DELETE, "users/\(UUID())",
          beforeRequest: { req in
            try authorize(&req, as: admin)
          },
          afterResponse: { res async in
            #expect(res.status == .notFound)
          })
      }
    }

    @Test("Deleting a user also deletes their posts, comments and activities")
    func deleteCascades() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)
        let user = try await makeUser(on: app.db)
        let forumPost = try await makeForumPost(by: user, in: try await makeForumCategory(on: app.db), on: app.db)
        try await makeForumComment(by: user, on: forumPost, on: app.db)
        let dangerPost = try await makeDangerPost(by: user, in: try await makeDangerCategory(on: app.db), on: app.db)
        try await makeDangerComment(by: user, on: dangerPost, on: app.db)
        try await makeActivity(by: user, on: app.db)

        try await app.testing().test(
          .DELETE, "users/\(user.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: admin)
          },
          afterResponse: { res async throws in
            #expect(res.status == .noContent)
            #expect(try await ForumPost.query(on: app.db).count() == 0)
            #expect(try await ForumComment.query(on: app.db).count() == 0)
            #expect(try await DangerPost.query(on: app.db).count() == 0)
            #expect(try await DangerComment.query(on: app.db).count() == 0)
            #expect(try await Activity.query(on: app.db).count() == 0)
          })
      }
    }

    @Test("A deleted user's token is rejected")
    func deletedUserToken() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)
        let user = try await makeUser(on: app.db)

        try await app.testing().test(
          .DELETE, "users/\(user.requireID())",
          beforeRequest: { req in
            try authorize(&req, as: admin)
          },
          afterResponse: { res async in
            #expect(res.status == .noContent)
          })

        try await app.testing().test(
          .GET, "users/me",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async in
            #expect(res.status == .unauthorized)
          })
      }
    }

    // MARK: - PATCH /users/:userID/ban

    @Test("Banning a user as a moderator sets the ban and rejects their token")
    func banAsModerator() async throws {
      try await withAppIncludingDB { app in
        let moderator = try await makeUser(adminRights: 1, on: app.db)
        let user = try await makeUser(on: app.db)

        try await app.testing().test(
          .PATCH, "users/\(user.requireID())/ban",
          beforeRequest: { req in
            try authorize(&req, as: moderator)
            try req.content.encode(BanUserDTO(banEndDate: Date().addingTimeInterval(86400)))
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let dto = try res.content.decode(GetUserDTO.self)
            #expect(try #require(dto.banEndDate) > Date())
          })

        try await app.testing().test(
          .GET, "users/me",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async in
            #expect(res.status == .unauthorized)
          })
      }
    }

    @Test("Banning a user as a regular user is forbidden")
    func banAsRegularUser() async throws {
      try await withAppIncludingDB { app in
        let regular = try await makeUser(on: app.db)
        let user = try await makeUser(on: app.db)

        try await app.testing().test(
          .PATCH, "users/\(user.requireID())/ban",
          beforeRequest: { req in
            try authorize(&req, as: regular)
            try req.content.encode(BanUserDTO(banEndDate: Date().addingTimeInterval(86400)))
          },
          afterResponse: { res async throws in
            #expect(res.status == .forbidden)
            #expect(try await User.find(user.id, on: app.db)?.banEndDate == nil)
          })
      }
    }

    @Test("Banning an unknown user returns 404")
    func banUnknownID() async throws {
      try await withAppIncludingDB { app in
        let moderator = try await makeUser(adminRights: 1, on: app.db)

        try await app.testing().test(
          .PATCH, "users/\(UUID())/ban",
          beforeRequest: { req in
            try authorize(&req, as: moderator)
            try req.content.encode(BanUserDTO(banEndDate: Date().addingTimeInterval(86400)))
          },
          afterResponse: { res async in
            #expect(res.status == .notFound)
          })
      }
    }

    @Test("Banning a user until a date in the past fails validation")
    func banInThePast() async throws {
      try await withAppIncludingDB { app in
        let moderator = try await makeUser(adminRights: 1, on: app.db)
        let user = try await makeUser(on: app.db)

        try await app.testing().test(
          .PATCH, "users/\(user.requireID())/ban",
          beforeRequest: { req in
            try authorize(&req, as: moderator)
            try req.content.encode(BanUserDTO(banEndDate: Date().addingTimeInterval(-86400)))
          },
          afterResponse: { res async in
            #expect(res.status == .badRequest)
          })
      }
    }

    // MARK: - DELETE /users/:userID/ban

    @Test("Unbanning a user as an admin clears the ban and lets them log in")
    func unbanAsAdmin() async throws {
      try await withAppIncludingDB { app in
        let admin = try await makeUser(adminRights: 2, on: app.db)
        let user = try await makeUser(
          email: "anne@example.com", banEndDate: Date().addingTimeInterval(86400), on: app.db)

        try await app.testing().test(
          .DELETE, "users/\(user.requireID())/ban",
          beforeRequest: { req in
            try authorize(&req, as: admin)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            #expect(try res.content.decode(GetUserDTO.self).banEndDate == nil)
          })

        try await app.testing().test(
          .POST, "users/login",
          beforeRequest: { req in
            try req.content.encode(LoginUserDTO(email: "anne@example.com", password: testPassword))
          },
          afterResponse: { res async in
            #expect(res.status == .ok)
          })
      }
    }

    @Test("Unbanning a user as a moderator is forbidden")
    func unbanAsModerator() async throws {
      try await withAppIncludingDB { app in
        let moderator = try await makeUser(adminRights: 1, on: app.db)
        let user = try await makeUser(banEndDate: Date().addingTimeInterval(86400), on: app.db)

        try await app.testing().test(
          .DELETE, "users/\(user.requireID())/ban",
          beforeRequest: { req in
            try authorize(&req, as: moderator)
          },
          afterResponse: { res async throws in
            #expect(res.status == .forbidden)
            #expect(try await User.find(user.id, on: app.db)?.banEndDate != nil)
          })
      }
    }

    // MARK: - GET /users/me

    @Test("Getting me returns my own data with my selected cycle")
    func getMe() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let cycleType = try await makeCycleType(on: app.db)
        try await user.$cycleTypeOwned.attach(cycleType, on: app.db)
        user.$cycleType.id = try cycleType.requireID()
        try await user.save(on: app.db)

        try await app.testing().test(
          .GET, "users/me",
          beforeRequest: { req in
            try authorize(&req, as: user)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let dto = try res.content.decode(GetUserDTO.self)
            #expect(dto.id == user.id)
            #expect(dto.cycleType?.id == cycleType.id)
            #expect(dto.cycleType?.name == "Gazelle")
          })
      }
    }

    @Test("Getting me requires a token")
    func getMeWithoutToken() async throws {
      try await withAppIncludingDB { app in
        try await app.testing().test(.GET, "users/me") { res async in
          #expect(res.status == .unauthorized)
        }
      }
    }

    @Test("Getting me with an invalid token returns 401")
    func getMeInvalidToken() async throws {
      try await withAppIncludingDB { app in
        try await app.testing().test(
          .GET, "users/me",
          beforeRequest: { req in
            req.headers.bearerAuthorization = BearerAuthorization(token: "garbage")
          },
          afterResponse: { res async in
            #expect(res.status == .unauthorized)
          })
      }
    }

    @Test("Getting me with an expired token returns 401")
    func getMeExpiredToken() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        var payload = UserPayload(id: try user.requireID())
        payload.expiration = Date().addingTimeInterval(-60)
        let expired = try JWTConfig.shared.sign(payload)

        try await app.testing().test(
          .GET, "users/me",
          beforeRequest: { req in
            req.headers.bearerAuthorization = BearerAuthorization(token: expired)
          },
          afterResponse: { res async in
            #expect(res.status == .unauthorized)
          })
      }
    }

    // MARK: - PATCH /users/me

    @Test("Patching me updates and trims my profile")
    func patchMe() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let dto = PatchUserDTO(
          firstName: "  New ", lastName: " Name  ", nickname: "newnick", bio: "  Hello  ")

        try await app.testing().test(
          .PATCH, "users/me",
          beforeRequest: { req in
            try authorize(&req, as: user)
            try req.content.encode(dto)
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let stored = try #require(try await User.find(user.id, on: app.db))
            #expect(stored.firstName == "New")
            #expect(stored.lastName == "Name")
            #expect(stored.nickname == "newnick")
            #expect(stored.bio == "Hello")
          })
      }
    }

    @Test("Patching me with an empty bio clears it")
    func patchMeEmptyBio() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        user.bio = "Old bio"
        try await user.save(on: app.db)

        try await app.testing().test(
          .PATCH, "users/me",
          beforeRequest: { req in
            try authorize(&req, as: user)
            try req.content.encode(PatchUserDTO(bio: ""))
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            #expect(try await User.find(user.id, on: app.db)?.bio == nil)
          })
      }
    }

    @Test("Patching me ignores admin rights and email in the body")
    func patchMeIgnoresProtectedFields() async throws {
      struct Body: Content {
        var firstName: String
        var adminRights: Int
        var email: String
      }

      try await withAppIncludingDB { app in
        let user = try await makeUser(email: "anne@example.com", on: app.db)

        try await app.testing().test(
          .PATCH, "users/me",
          beforeRequest: { req in
            try authorize(&req, as: user)
            try req.content.encode(Body(firstName: "New", adminRights: 2, email: "hacker@example.com"))
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            let stored = try #require(try await User.find(user.id, on: app.db))
            #expect(stored.firstName == "New")
            #expect(stored.adminRights == 0)
            #expect(stored.email == "anne@example.com")
          })
      }
    }

    @Test("Patching me with a cycle type selects it")
    func patchMeCycle() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)
        let cycleType = try await makeCycleType(on: app.db)

        try await app.testing().test(
          .PATCH, "users/me",
          beforeRequest: { req in
            try authorize(&req, as: user)
            try req.content.encode(PatchUserDTO(cycleTypeId: cycleType.requireID()))
          },
          afterResponse: { res async throws in
            #expect(res.status == .ok)
            #expect(try res.content.decode(GetUserDTO.self).cycleType?.id == cycleType.id)
          })
      }
    }

    @Test("Patching me with a nonexistent cycle type returns 404")
    func patchMeNonexistentCycle() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)

        try await app.testing().test(
          .PATCH, "users/me",
          beforeRequest: { req in
            try authorize(&req, as: user)
            try req.content.encode(PatchUserDTO(cycleTypeId: UUID()))
          },
          afterResponse: { res async in
            #expect(res.status == .notFound)
          })
      }
    }

    @Test("Patching me with a nickname already in use returns 409")
    func patchMeDuplicateNickname() async throws {
      try await withAppIncludingDB { app in
        try await makeUser(nickname: "taken", on: app.db)
        let user = try await makeUser(on: app.db)

        try await app.testing().test(
          .PATCH, "users/me",
          beforeRequest: { req in
            try authorize(&req, as: user)
            try req.content.encode(PatchUserDTO(nickname: "taken"))
          },
          afterResponse: { res async in
            #expect(res.status == .conflict)
          })
      }
    }

    // MARK: - PATCH /users/me/password

    @Test("Changing my password with the right old password replaces it")
    func changePassword() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(email: "anne@example.com", on: app.db)
        let newPassword = "N3wPassw0rd!"

        try await app.testing().test(
          .PATCH, "users/me/password",
          beforeRequest: { req in
            try authorize(&req, as: user)
            try req.content.encode(
              PatchUserPasswordDTO(oldPassword: testPassword, newPassword: newPassword))
          },
          afterResponse: { res async in
            #expect(res.status == .ok)
          })

        try await app.testing().test(
          .POST, "users/login",
          beforeRequest: { req in
            try req.content.encode(LoginUserDTO(email: "anne@example.com", password: newPassword))
          },
          afterResponse: { res async in
            #expect(res.status == .ok)
          })

        try await app.testing().test(
          .POST, "users/login",
          beforeRequest: { req in
            try req.content.encode(LoginUserDTO(email: "anne@example.com", password: testPassword))
          },
          afterResponse: { res async in
            #expect(res.status == .unauthorized)
          })
      }
    }

    @Test("Changing my password with a wrong old password is forbidden")
    func changePasswordWrongOld() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)

        try await app.testing().test(
          .PATCH, "users/me/password",
          beforeRequest: { req in
            try authorize(&req, as: user)
            try req.content.encode(
              PatchUserPasswordDTO(oldPassword: "Wr0ngPass!", newPassword: "N3wPassw0rd!"))
          },
          afterResponse: { res async in
            #expect(res.status == .forbidden)
          })
      }
    }

    @Test("Changing my password to a weak one fails validation")
    func changePasswordWeakNew() async throws {
      try await withAppIncludingDB { app in
        let user = try await makeUser(on: app.db)

        try await app.testing().test(
          .PATCH, "users/me/password",
          beforeRequest: { req in
            try authorize(&req, as: user)
            try req.content.encode(PatchUserPasswordDTO(oldPassword: testPassword, newPassword: "weak"))
          },
          afterResponse: { res async in
            #expect(res.status == .badRequest)
          })
      }
    }
  }
}
