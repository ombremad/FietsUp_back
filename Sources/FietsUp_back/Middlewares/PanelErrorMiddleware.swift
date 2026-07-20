//
//  PanelErrorMiddleware.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 20/07/2026.
//

import Vapor

struct PanelErrorMiddleware: AsyncMiddleware {
  func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
    do {
      return try await next.respond(to: request)
    } catch {
      let reason = (error as? (any AbortError))?.reason ?? "Something went wrong."
      let status = (error as? (any AbortError))?.status ?? .internalServerError

      struct ErrorContext: Encodable {
        let reason: String
      }
      
      let view = try await request.view.render("error", ErrorContext(reason: reason))
      let response = try await view.encodeResponse(for: request).get()
      response.status = status
      return response      
    }
  }
}
