import NIOSSL
import Fluent
import FluentMySQLDriver
import Vapor
import Gatekeeper
import VaporToOpenAPI

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // MySQL
    app.databases.use(DatabaseConfigurationFactory.mysql(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? MySQLConfiguration.ianaPortNumber,
        username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
        password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
        database: Environment.get("DATABASE_NAME") ?? "vapor_database"
    ), as: .mysql)
        
    // Cors
    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .none,
        allowedMethods: [],
        allowedHeaders: []
    )
    app.middleware.use(CORSMiddleware(configuration: corsConfiguration))
    
    // Gatekeeper
    app.gatekeeper.config = .init(maxRequests: 60, per: .minute)
    app.gatekeeper.config = .init(maxRequests: 10, per: .second)
    app.middleware.use(GatekeeperMiddleware())
    
    // Json strategies
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    ContentConfiguration.global.use(encoder: encoder, for: .json)
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    decoder.dateDecodingStrategy = .iso8601
    ContentConfiguration.global.use(decoder: decoder, for: .json)

    // migrations and routes
    app.migrations.add(CreateTodo())
    try routes(app)
}
