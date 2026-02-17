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
                    "BearerAuth": .value(SecuritySchemeObject(
                        type: .http,
                        scheme: "bearer",
                        bearerFormat: "JWT"
                    )),
                    "AdminBearer": .value(SecuritySchemeObject(
                        type: .http,
                        description: "Requires a level of adminRights >= 2",
                        scheme: "bearer",
                        bearerFormat: "JWT"
                    ))
                ]
            )
        )
    }
    .excludeFromOpenAPI()
    
    // controllers registration
    try app.register(collection: UserController())
}
