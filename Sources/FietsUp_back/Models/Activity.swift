import Fluent

import struct Foundation.UUID

final class Activity: Model, @unchecked Sendable {
  static let schema = "activities"

  @ID(key: .id) var id: UUID?

  @Field(key: "start_date") var startDate: Date
  @Field(key: "end_date") var endDate: Date
  @Field(key: "length") var length: Int
  @Field(key: "distance") var distance: Int

  @Parent(key: "id_user") var user: User

  init() {}

  convenience init(from dto: CreateActivityDTO, userID: UUID) {
    self.init()

    // computed
    self.length = Int(dto.endDate.timeIntervalSince(dto.startDate) / 60)
    self.$user.id = userID

    // user provided
    self.startDate = dto.startDate
    self.endDate = dto.endDate
    self.distance = dto.distance
  }
}
