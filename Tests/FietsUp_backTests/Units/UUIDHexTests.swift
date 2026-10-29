@testable import FietsUp_back
import VaporTesting
import Testing

@Suite("UUID Hex Tests")
struct UUIDHexTests {
  @Test("A UUID survives a round trip through its hex string")
  func roundTrip() {
    let uuid = UUID()
    #expect(uuid.hexString.count == 32)
    #expect(!uuid.hexString.contains("-"))
    #expect(UUID(hex: uuid.hexString) == uuid)
  }

  @Test("Lowercase hex, as MySQL may return it, is accepted")
  func lowercaseHex() {
    let uuid = UUID()
    #expect(UUID(hex: uuid.hexString.lowercased()) == uuid)
  }

  @Test("Malformed hex gives nil", arguments: ["", "not-hex", "1234", String(repeating: "Z", count: 32)])
  func malformedHex(hex: String) {
    #expect(UUID(hex: hex) == nil)
  }
}
