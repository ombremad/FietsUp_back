//
//  ForumCommentController.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 13/04/2026.
//

import Vapor
import Fluent

struct ForumCommentController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
      
      let request = routes.grouped("forum", "comments")
      
      let userProtected = request
        .grouped(JWTMiddleware())
        .groupedOpenAPI(auth: .bearer(id: "BearerAuth", format: "JWT"))

      let modProtected = request
          .grouped(RequireAdminLevelMiddleware(minimumLevel: 1))
          .groupedOpenAPI(auth: .bearer(id: "ModBearer", format: "JWT"))

//        userProtected.post(use: self.create)
//        userProtected.get(use: self.getAll)
//
//        modProtected.patch(":commentID", use: self.patchByID)
//        modProtected.delete(":commentID", use: self.deleteByID)
    }
}
