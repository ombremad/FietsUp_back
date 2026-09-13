import Fluent
import Foundation

final class Rating: Model, @unchecked Sendable {
  static let schema = "ratings"

  @ID(key: .id) var id: UUID?

  @Field(key: "note") var note: Int

  @Parent(key: "id_user") var user: User
  @Parent(key: "id_place") var place: Place

  init() {}
  
  convenience init(from dto: CreateOrPatchRatingDTO, userID: UUID, placeID: UUID) {
    self.init()
    
      // computed
    self.$user.id = userID
    self.$place.id = placeID

      // user provided
    self.note = dto.note
  }
}

extension Rating {
  func update(with dto: CreateOrPatchRatingDTO) {
    self.note = dto.note
  }
}
