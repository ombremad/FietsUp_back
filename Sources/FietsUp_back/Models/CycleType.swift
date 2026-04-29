import Fluent

import struct Foundation.UUID

final class CycleType: Model, @unchecked Sendable {
  static let schema = "cycle_types"

  @ID(key: .id) var id: UUID?

  @Field(key: "name") var name: String
  @Field(key: "file_link") var fileLink: String

  @Children(for: \.$cycleType) var users: [User]

  @Siblings(through: CycleTypeOwnership.self, from: \.$cycleType, to: \.$user) var owners: [User]

  init() {}
  
  convenience init(from dto: CreateCycleTypeDTO) {
    self.init()
    
      // user provided
    self.name = dto.name.trimmingCharacters(in: .whitespacesAndNewlines)
    self.fileLink = dto.fileLink
  }
}

extension CycleType {
  func patch(with dto: PatchCycleTypeDTO) {
    if let name = dto.name { self.name = name.trimmingCharacters(in: .whitespacesAndNewlines) }
    if let fileLink = dto.fileLink { self.fileLink = fileLink }
  }
}
