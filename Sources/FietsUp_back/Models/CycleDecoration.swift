import Fluent

import struct Foundation.UUID

final class CycleDecoration: Model, @unchecked Sendable {
  static let schema = "cycle_decorations"

  @ID(key: .id) var id: UUID?

  @Field(key: "name") var name: String
  @Field(key: "file_link") var fileLink: String

  @Children(for: \.$cycleDecoration) var users: [User]

  @Siblings(through: CycleDecorationOwnership.self, from: \.$cycleDecoration, to: \.$user)
  var owners: [User]

  init() {}
  
  convenience init(from dto: CreateCycleDecorationDTO) {
    self.init()
    
      // user provided
    self.name = dto.name.trimmingCharacters(in: .whitespacesAndNewlines)
    self.fileLink = dto.fileLink
  }
}

extension CycleDecoration {
  func patch(with dto: PatchCycleDecorationDTO) {
    if let name = dto.name { self.name = name.trimmingCharacters(in: .whitespacesAndNewlines) }
    if let fileLink = dto.fileLink { self.fileLink = fileLink }
  }
}
