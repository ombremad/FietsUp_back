@testable import FietsUp_back
import Fluent
import SQLKit
import VaporTesting
import Testing

// Seed factories: each saves straight to the database and returns the saved model.

// MARK: - Cycles

@discardableResult
func makeCycleColor(name: String = "Red", color: String = "FF0000", on db: any Database) async throws -> CycleColor {
  let model = CycleColor(from: CreateCycleColorDTO(name: name, color: color))
  try await model.save(on: db)
  return model
}

@discardableResult
func makeCycleType(name: String = "Gazelle", fileLink: String = "https://example.com/gazelle.png", on db: any Database) async throws -> CycleType {
  let model = CycleType(from: CreateCycleTypeDTO(name: name, fileLink: fileLink))
  try await model.save(on: db)
  return model
}

@discardableResult
func makeCycleDecoration(name: String = "Stars", fileLink: String = "https://example.com/stars.png", on db: any Database) async throws -> CycleDecoration {
  let model = CycleDecoration(from: CreateCycleDecorationDTO(name: name, fileLink: fileLink))
  try await model.save(on: db)
  return model
}

/// Gives the user a cycle type they own and have selected, so embedded public users should expose it.
@discardableResult
func selectCycle(for user: User, on db: any Database) async throws -> CycleType {
  let cycleType = try await makeCycleType(on: db)
  try await user.$cycleTypeOwned.attach(cycleType, on: db)
  user.$cycleType.id = try cycleType.requireID()
  try await user.save(on: db)
  return cycleType
}

// MARK: - Categories

@discardableResult
func makeModerationCategory(name: String = "Spam", on db: any Database) async throws -> ModerationCategory {
  let model = ModerationCategory(from: CreateModerationCategoryDTO(name: name))
  try await model.save(on: db)
  return model
}

@discardableResult
func makeDangerCategory(name: String = "Pothole", iconName: String = "pothole", on db: any Database) async throws -> DangerCategory {
  let model = DangerCategory(from: CreateDangerCategoryDTO(name: name, iconName: iconName))
  try await model.save(on: db)
  return model
}

@discardableResult
func makeForumCategory(name: String = "General", details: String? = nil, on db: any Database) async throws -> ForumCategory {
  let model = ForumCategory(from: CreateForumCategoryDTO(name: name, details: details))
  try await model.save(on: db)
  return model
}

@discardableResult
func makePlaceCategory(name: String = "Repair shop", iconName: String = "wrench", on db: any Database) async throws -> PlaceCategory {
  let model = PlaceCategory(from: CreatePlaceCategoryDTO(name: name, iconName: iconName))
  try await model.save(on: db)
  return model
}

// MARK: - Forum

@discardableResult
func makeForumPost(
  title: String = "Hello", content: String = "First post",
  by user: User, in category: ForumCategory, on db: any Database
) async throws -> ForumPost {
  let model = ForumPost(
    from: CreateForumPostDTO(title: title, content: content),
    userID: try user.requireID(), forumCategoryID: try category.requireID())
  try await model.save(on: db)
  return model
}

@discardableResult
func makeForumComment(content: String = "A comment", by user: User, on post: ForumPost, on db: any Database) async throws -> ForumComment {
  let model = ForumComment(
    from: CreateForumCommentDTO(content: content),
    userID: try user.requireID(), forumPostID: try post.requireID())
  try await model.save(on: db)
  return model
}

// MARK: - Dangers

@discardableResult
func makeDangerPost(
  title: String = "Pothole", content: String = "Big hole",
  latitude: Double = 48.8566, longitude: Double = 2.3522,
  by user: User, in category: DangerCategory, on db: any Database
) async throws -> DangerPost {
  let model = DangerPost(
    from: CreateDangerPostDTO(title: title, content: content, latitude: latitude, longitude: longitude),
    userID: try user.requireID(), dangerCategoryID: try category.requireID())
  try await model.save(on: db)
  return model
}

@discardableResult
func makeDangerComment(content: String = "Still there", by user: User, on post: DangerPost, on db: any Database) async throws -> DangerComment {
  let model = DangerComment(
    from: CreateDangerCommentDTO(content: content),
    userID: try user.requireID(), dangerPostID: try post.requireID())
  try await model.save(on: db)
  return model
}

/// Moves a danger post's creation and last activity dates into the past, bypassing Fluent's timestamps.
func age(_ post: DangerPost, byDays days: Int, on db: any Database) async throws {
  let sql = try #require(db as? any SQLDatabase)
  let hexID = try post.requireID().hexString
  try await sql.raw("""
    UPDATE danger_posts
    SET creation_date = NOW() - INTERVAL \(bind: days) DAY,
        last_activity_date = NOW() - INTERVAL \(bind: days) DAY
    WHERE id = UNHEX(\(bind: hexID))
    """).run()
}

// MARK: - Places

@discardableResult
func makePlace(
  name: String = "Bike shop", latitude: Double = 48.8566, longitude: Double = 2.3522,
  categories: [PlaceCategory], on db: any Database
) async throws -> Place {
  let model = Place(from: CreatePlaceDTO(
    name: name, categoriesIds: try categories.map { try $0.requireID() },
    latitude: latitude, longitude: longitude))
  try await model.save(on: db)
  try await model.$categories.attach(categories, on: db)
  return model
}

@discardableResult
func makeRating(note: Int, by user: User, on place: Place, on db: any Database) async throws -> Rating {
  let model = Rating(from: CreateOrPatchRatingDTO(note: note), userID: try user.requireID(), placeID: try place.requireID())
  try await model.save(on: db)
  return model
}

// MARK: - Activities

@discardableResult
func makeActivity(
  start: Date = Date().addingTimeInterval(-7200), end: Date = Date().addingTimeInterval(-3600),
  distance: Int = 10_000, by user: User, on db: any Database
) async throws -> Activity {
  let model = Activity(from: CreateActivityDTO(startDate: start, endDate: end, distance: distance), userID: try user.requireID())
  try await model.save(on: db)
  return model
}

// MARK: - Reports

@discardableResult
func makeReport(on post: DangerPost, by user: User, category: ModerationCategory, on db: any Database) async throws -> DangerPostReport {
  let model = DangerPostReport(
    from: CreateReportDTO(details: "Report", categoryId: try category.requireID()),
    userID: try user.requireID(), dangerPostID: try post.requireID())
  try await model.save(on: db)
  return model
}

@discardableResult
func makeReport(on comment: DangerComment, by user: User, category: ModerationCategory, on db: any Database) async throws -> DangerCommentReport {
  let model = DangerCommentReport(
    from: CreateReportDTO(details: "Report", categoryId: try category.requireID()),
    userID: try user.requireID(), dangerCommentID: try comment.requireID())
  try await model.save(on: db)
  return model
}

@discardableResult
func makeReport(on post: ForumPost, by user: User, category: ModerationCategory, on db: any Database) async throws -> ForumPostReport {
  let model = ForumPostReport(
    from: CreateReportDTO(details: "Report", categoryId: try category.requireID()),
    userID: try user.requireID(), forumPostID: try post.requireID())
  try await model.save(on: db)
  return model
}

@discardableResult
func makeReport(on comment: ForumComment, by user: User, category: ModerationCategory, on db: any Database) async throws -> ForumCommentReport {
  let model = ForumCommentReport(
    from: CreateReportDTO(details: "Report", categoryId: try category.requireID()),
    userID: try user.requireID(), forumCommentID: try comment.requireID())
  try await model.save(on: db)
  return model
}

// MARK: - Dates

/// Overwrites a timestamp column with `NOW()` minus some seconds, bypassing Fluent's automatic timestamps.
/// MySQL TIMESTAMPs only keep whole seconds, so tests that depend on ordering set dates explicitly.
/// The date is computed by the server: binding a Swift `Date` can shift it by the connection's time zone.
func setDate(_ column: String, in table: String, id: UUID, secondsAgo: Int, on db: any Database) async throws {
  let sql = try #require(db as? any SQLDatabase)
  try await sql.raw("""
    UPDATE \(ident: table) SET \(ident: column) = NOW() - INTERVAL \(bind: secondsAgo) SECOND
    WHERE id = UNHEX(\(bind: id.hexString))
    """).run()
}
