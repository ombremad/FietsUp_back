//
//  WebPanelAuthMiddleware.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 20/07/2026.
//

import Vapor

final class PanelAuthMiddleware: AsyncMiddleware {
  func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
    guard let token = request.cookies["admin_token"]?.string else {
      return request.redirect(to: "/panel/login")
    }
    
    let user: User
    do {
      user = try await AuthHelper.verifyUser(token: token, on: request)
    } catch {
      return request.redirect(to: "/panel/login")
    }
    
    guard user.adminRights >= 2 else {
      return request.redirect(to: "/panel/login")
    }
    
    request.auth.login(user)
    return try await next.respond(to: request)
  }
}
