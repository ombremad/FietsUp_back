@testable import FietsUp_back
import VaporTesting
import Testing

@Suite("App Tests")
struct AppTests {
  @Test("The root route answers")
  func root() async throws {
    try await withApp(configure: configure) { app in
      try await app.testing().test(.GET, "") { res async in
        #expect(res.status == .ok)
        #expect(res.body.string == "It works!")
      }
    }
  }

  @Test("The OpenAPI document is served and lists the app's routes")
  func swagger() async throws {
    try await withApp(configure: configure) { app in
      try await app.testing().test(.GET, "swagger/swagger.json") { res async throws in
        #expect(res.status == .ok)
        let json = try #require(
          try JSONSerialization.jsonObject(with: Data(res.body.readableBytesView)) as? [String: Any])
        let paths = try #require(json["paths"] as? [String: Any])
        #expect(paths.keys.contains("/users/login"))
        #expect(paths.keys.contains("/moderation/categories"))
      }
    }
  }
}
