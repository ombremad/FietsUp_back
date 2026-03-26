import Fluent

import struct Foundation.UUID

final class DangerCategory: Model, @unchecked Sendable {
  static let schema = "danger_categories"

  @ID(key: .id) var id: UUID?

  @Field(key: "name") var name: String
  @Field(key: "icon_name") var iconName: String

  @Children(for: \.$dangerCategory) var dangerPosts: [DangerPost]

  init() {}
  
  convenience init(from dto: CreateDangerCategoryDTO) {
    self.init()
    
    // user provided
    self.name = dto.name.trimmingCharacters(in: .whitespacesAndNewlines)
    self.iconName = dto.iconName
  }
}

extension DangerCategory {
  func patch(with dto: PatchDangerCategoryDTO) {
    if let name = dto.name { self.name = name.trimmingCharacters(in: .whitespacesAndNewlines) }
    if let iconName = dto.iconName { self.iconName = iconName }
  }
}
