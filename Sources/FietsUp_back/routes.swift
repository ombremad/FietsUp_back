import Fluent
import Vapor
import VaporToOpenAPI

func routes(_ app: Application) throws {

  // it works!
  app.get { req async in
    "It works!"
  }
  .excludeFromOpenAPI()

  // OpenAPI documentation
  app.get("swagger", "swagger.json") { req in
    req.application.routes.openAPI(
      info: InfoObject(
        title: "Fiets'Up API",
        description: "Internal API for Fiets'Up, an iOS cycling awareness and tracking app.",
        version: "1.0.0"
      ),
      components: ComponentsObject(
        securitySchemes: [
          "BearerAuth": .value(
            SecuritySchemeObject(
              type: .http,
              scheme: "bearer",
              bearerFormat: "JWT"
            )),
          "ModBearer": .value(
            SecuritySchemeObject(
              type: .http,
              description: "Requires a level of adminRights >= 1",
              scheme: "bearer",
              bearerFormat: "JWT"
            )),
          "AdminBearer": .value(
            SecuritySchemeObject(
              type: .http,
              description: "Requires a level of adminRights >= 2",
              scheme: "bearer",
              bearerFormat: "JWT"
            )),
        ]
      )
    )
  }
  .excludeFromOpenAPI()

  // CONTROLLERS
  // feature: users management
  try app.register(collection: UserController())
  
  // feature: activities
  try app.register(collection: ActivityController())
  
  // feature: dangers
  try app.register(collection: DangerPostController())
  try app.register(collection: DangerCategoryController())
  try app.register(collection: DangerCommentController())
  
  // feature: forum
  try app.register(collection: ForumPostController())
  try app.register(collection: ForumCategoryController())
  try app.register(collection: ForumCommentController())
  
  // feature: moderation & reports
  try app.register(collection: ModerationCategoryController())
  try app.register(collection: DangerCommentReportController())
  try app.register(collection: DangerPostReportController())
  try app.register(collection: ForumCommentReportController())
  try app.register(collection: ForumPostReportController())
  
  // feature: places
  try app.register(collection: PlaceController())
  try app.register(collection: PlaceCategoryController())
}
