import Fluent
import FluentMySQLDriver
import Gatekeeper
import NIOSSL
import Vapor
import VaporToOpenAPI

// configures your application
public func configure(_ app: Application) async throws {
  // serve files from /Public folder
  // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

  // MySQL
  var tls = TLSConfiguration.makeClientConfiguration()
  if Environment.get("DATABASE_HOST") == nil || Environment.get("DATABASE_HOST") == "localhost" {
    tls.certificateVerification = .none
  }
  
  app.databases.use(
    DatabaseConfigurationFactory.mysql(
      hostname: Environment.get("DATABASE_HOST") ?? "localhost",
      port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:))
      ?? MySQLConfiguration.ianaPortNumber,
      username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
      password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
      database: Environment.get("DATABASE_NAME") ?? "vapor_database",
      tlsConfiguration: tls
    ), as: .mysql)
  
  // Cors
  let corsConfiguration = CORSMiddleware.Configuration(
    allowedOrigin: .none,
    allowedMethods: [],
    allowedHeaders: []
  )
  app.middleware.use(CORSMiddleware(configuration: corsConfiguration))

  // Gatekeeper
  app.gatekeeper.config = .init(maxRequests: 100, per: .minute)
  app.gatekeeper.config = .init(maxRequests: 20, per: .second)
  app.middleware.use(GatekeeperMiddleware())

  // Json strategies
  let encoder = JSONEncoder()
  encoder.dateEncodingStrategy = .iso8601
  ContentConfiguration.global.use(encoder: encoder, for: .json)
  let decoder = JSONDecoder()
  decoder.keyDecodingStrategy = .convertFromSnakeCase
  decoder.dateDecodingStrategy = .iso8601
  ContentConfiguration.global.use(decoder: decoder, for: .json)
  
  // Migrations
  
  // Tables
  app.migrations.add(CreateCycleColors())
  app.migrations.add(CreateCycleDecorations())
  app.migrations.add(CreateCycleTypes())
  app.migrations.add(CreateUsers())
  app.migrations.add(CreateDangerCategories())
  app.migrations.add(CreateForumCategories())
  app.migrations.add(CreateModerationCategories())
  app.migrations.add(CreatePlaceCategories())
  app.migrations.add(CreatePlaces())
  app.migrations.add(CreateActivities())
  app.migrations.add(CreateRatings())
  app.migrations.add(CreateDangerPosts())
  app.migrations.add(CreateDangerComments())
  app.migrations.add(CreateDangerPostReports())
  app.migrations.add(CreateDangerCommentReports())
  app.migrations.add(CreateForumPosts())
  app.migrations.add(CreateForumComments())
  app.migrations.add(CreateForumPostReports())
  app.migrations.add(CreateForumCommentReports())

  // Ownerships & pivots
  app.migrations.add(CreateCycleColorOwnership())
  app.migrations.add(CreateCycleDecorationOwnership())
  app.migrations.add(CreateCycleTypeOwnership())
  app.migrations.add(CreatePlaceCategorization())
  app.migrations.add(CreateDangerCommentFavs())
  app.migrations.add(CreateDangerCommentLikes())
  app.migrations.add(CreateDangerPostFavs())
  app.migrations.add(CreateDangerPostLikes())
  app.migrations.add(CreateForumCommentFavs())
  app.migrations.add(CreateForumCommentLikes())
  app.migrations.add(CreateForumPostFavs())
  app.migrations.add(CreateForumPostLikes())

  // Indexes & events
  app.migrations.add(AddPlacesSpatialIndex())
  app.migrations.add(CreateActivityDistanceTriggers())
  app.migrations.add(CreateForumActivityTriggers())
  app.migrations.add(CreateDangerActivityTriggers())
  app.migrations.add(CreateLocationTriggers())
  app.migrations.add(CreateWeeklyStreakReset())

  // Run migrations (uncomment to run)
  // try await app.autoMigrate()
  
  // Routes
  try routes(app)
}
