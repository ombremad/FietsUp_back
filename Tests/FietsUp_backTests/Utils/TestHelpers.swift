@testable import FietsUp_back
import Fluent
import VaporTesting
import Testing

// Every suite migrates and reverts the same test database, so suites must not run in parallel.
// Declare each suite inside this one: `extension DatabaseTests { @Suite("…") struct … }`
@Suite(.serialized)
struct DatabaseTests {}

let testPassword = "Passw0rd!"

func withAppIncludingDB(_ test: (Application) async throws -> Void) async throws {
  let app = try await Application.make(.testing)
  app.logger.logLevel = .warning
  do {
    try await configure(app)
    try await app.autoMigrate()
    try await test(app)
    try await app.autoRevert()
  } catch {
    try? await app.autoRevert()
    try await app.asyncShutdown()
    throw error
  }
  try await app.asyncShutdown()
}

@discardableResult
func makeUser(
  adminRights: Int = 0,
  nickname: String = UUID().uuidString,
  email: String = "\(UUID().uuidString)@example.com",
  password: String = testPassword,
  banEndDate: Date? = nil,
  on db: any Database
) async throws -> User {
  let user = User()
  user.firstName = "Test"
  user.lastName = "User"
  user.nickname = nickname
  user.email = email
  user.password = try Bcrypt.hash(password)
  user.adminRights = adminRights
  user.banEndDate = banEndDate
  user.streak = 0
  user.streakUpdatedThisWeek = false
  user.totalElapsedDistance = 0
  try await user.save(on: db)
  return user
}

func token(for user: User) throws -> String {
  try JWTConfig.shared.sign(UserPayload(id: user.requireID()))
}

func authorize(_ req: inout TestingHTTPRequest, as user: User) throws {
  req.headers.bearerAuthorization = BearerAuthorization(token: try token(for: user))
}
