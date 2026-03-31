import Fluent

import struct Foundation.UUID

final class DangerPost: Model, @unchecked Sendable {
  static let schema = "danger_posts"

  @ID(key: .id) var id: UUID?

  @Field(key: "title") var title: String
  @Field(key: "content") var content: String
  @Field(key: "latitude") var latitude: Double
  @Field(key: "longitude") var longitude: Double
  @OptionalField(key: "last_activity_date") var lastActivityDate: Date?

  @Timestamp(key: "creation_date", on: .create) var creationDate: Date?

  @Parent(key: "id_user") var user: User
  @Parent(key: "id_danger_category") var dangerCategory: DangerCategory

  @Children(for: \.$dangerPost) var dangerComments: [DangerComment]
  @Children(for: \.$dangerPost) var dangerPostReports: [DangerPostReport]

  @Siblings(through: DangerPostFav.self, from: \.$dangerPost, to: \.$user) var usersFaved: [User]
  @Siblings(through: DangerPostLike.self, from: \.$dangerPost, to: \.$user) var usersLiked: [User]

  init() {}
  
  convenience init(from dto: CreateDangerPostDTO, userID: UUID, dangerCategoryID: UUID) {
    self.init()
    
    // computed
    self.$user.id = userID
    self.$dangerCategory.id = dangerCategoryID
    
    // user provided
    self.title = dto.title.trimmingCharacters(in: .whitespacesAndNewlines)
    self.content = dto.content.trimmingCharacters(in: .whitespacesAndNewlines)
    self.latitude = dto.latitude
    self.longitude = dto.longitude
  }
}

extension DangerPost {
  func patch(with dto: PatchDangerPostDTO) {
    if let title = dto.title { self.title = title.trimmingCharacters(in: .whitespacesAndNewlines) }
    if let content = dto.content { self.content = content.trimmingCharacters(in: .whitespacesAndNewlines) }
    if let latitude = dto.latitude { self.latitude = latitude }
    if let longitude = dto.longitude { self.longitude = longitude }
  }
}
