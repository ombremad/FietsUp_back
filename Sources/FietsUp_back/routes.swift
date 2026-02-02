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
                version: "1.0.0",
            )
        )
    }
    .excludeFromOpenAPI()
    
    // controllers registration
    try app.register(collection: UserController())
}
