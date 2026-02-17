//
//  RequireAdminLevelMiddleware.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 17/02/2026.
//

import Vapor

struct RequireAdminLevelMiddleware: AsyncMiddleware {
    let minimumLevel: Int
    
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        let payload = try request.auth.require(UserPayload.self)
        
        guard let user = try await User.find(payload.id, on: request.db) else {
            throw Abort(.notFound, reason: "User not found")
        }
        guard user.adminRights >= minimumLevel else {
            throw Abort(.forbidden, reason: "Insufficient privileges")
        }
        
        request.storage[ResolvedUserKey.self] = user
        return try await next.respond(to: request)
    }
}

struct ResolvedUserKey: StorageKey {
    typealias Value = User
}

extension Request {
    var resolvedUser: User {
        get throws {
            guard let user = storage[ResolvedUserKey.self] else {
                throw Abort(.internalServerError)
            }
            return user
        }
    }
}
