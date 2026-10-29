@testable import FietsUp_back
import VaporTesting
import Testing

@Suite("Decoding Tests")
struct DecodingTests {
  private func decode(_ json: String) throws -> PatchForumCategoryDTO {
    try JSONDecoder().decode(PatchForumCategoryDTO.self, from: Data(json.utf8))
  }

  @Test("A missing nullable patch field means \"leave unchanged\"")
  func missingField() throws {
    let dto = try decode(#"{"name": "General"}"#)
    #expect(dto.name == "General")
    #expect(dto.details == nil)
  }

  @Test("A null nullable patch field means \"clear it\"")
  func nullField() throws {
    let dto = try decode(#"{"details": null}"#)
    #expect(dto.details == .some(nil))
  }

  @Test("A present nullable patch field means \"set it\"")
  func presentField() throws {
    let dto = try decode(#"{"details": "About bikes"}"#)
    #expect(dto.details == .some("About bikes"))
  }
}
