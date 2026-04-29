import Fluent

import struct Foundation.UUID

final class CycleColor: Model, @unchecked Sendable {
  static let schema = "cycle_colors"

  @ID(key: .id) var id: UUID?

  @Field(key: "name") var name: String
  @Field(key: "color") var color: String

  @Children(for: \.$cycleColor) var users: [User]

  @Siblings(through: CycleColorOwnership.self, from: \.$cycleColor, to: \.$user) var owners: [User]

  init() {}
  
  convenience init(from dto: CreateCycleColorDTO) {
    self.init()
    
      // user provided
    self.name = dto.name.trimmingCharacters(in: .whitespacesAndNewlines)
    self.color = dto.color.lowercased()
  }
}

extension CycleColor {
  func patch(with dto: PatchCycleColorDTO) {
    if let name = dto.name { self.name = name.trimmingCharacters(in: .whitespacesAndNewlines) }
    if let color = dto.color { self.color = color.lowercased() }
  }
}
