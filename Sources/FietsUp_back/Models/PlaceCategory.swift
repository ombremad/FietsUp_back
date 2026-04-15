import Fluent

import struct Foundation.UUID

final class PlaceCategory: Model, @unchecked Sendable {
  static let schema = "place_categories"

  @ID(key: .id) var id: UUID?

  @Field(key: "name") var name: String
  @Field(key: "icon_name") var iconName: String

  @Siblings(through: PlaceCategorization.self, from: \.$placeCategory, to: \.$place) var places:
    [Place]

  init() {}
  
  convenience init(from dto: CreatePlaceCategoryDTO) {
    self.init()
    
      // user provided
    self.name = dto.name.trimmingCharacters(in: .whitespacesAndNewlines)
    self.iconName = dto.iconName
  }
}

extension PlaceCategory {
  func patch(with dto: PatchPlaceCategoryDTO) {
    if let name = dto.name { self.name = name.trimmingCharacters(in: .whitespacesAndNewlines) }
    if let iconName = dto.iconName { self.iconName = iconName }
  }
}
