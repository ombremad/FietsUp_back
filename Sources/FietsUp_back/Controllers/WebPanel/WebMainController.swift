//
//  WebMainController.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 20/07/2026.
//

import Fluent
import Vapor

struct WebMainController: RouteCollection {
  func boot(routes: any RoutesBuilder) throws {
    let panel = routes
      .grouped("panel")
      .grouped(PanelErrorMiddleware())
    let protected = panel.grouped(PanelAuthMiddleware())
    
    panel.get(use: self.index)
    panel.get("login", use: self.loginPage)
    panel.post("login", use: self.login)
    panel.get("logout", use: self.logout)
    protected.get("home", use: self.home)
  }
  
  @Sendable
  func index(req: Request) async throws -> Response {
    req.redirect(to: "/panel/home")
  }
  
  @Sendable
  func loginPage(req: Request) async throws -> View {
    try await req.view.render("/login")
  }
  
  @Sendable
  func login(req: Request) async throws -> Response {
    struct LoginData: Content {
      let email: String
      let password: String
    }
    let data = try req.content.decode(LoginData.self)
    
    guard let user = try await User.query(on: req.db)
      .filter(\.$email == data.email)
      .first(),
          try Bcrypt.verify(data.password, created: user.password),
          user.adminRights >= 2
    else {
      let view = req.view.render("/login", ["error": "Invalid credentials"])
      return try await view.encodeResponse(for: req).get()
    }
    
    let userID = try user.requireID()
    let token = try JWTConfig.shared.sign(UserPayload(id: userID))
    let response = req.redirect(to: "/panel/home")
    response.cookies["admin_token"] = .init(string: token, isSecure: true, isHTTPOnly: true, sameSite: .strict)
    return response
  }
  
  @Sendable
  func logout(req: Request) async throws -> Response {
    let response = req.redirect(to: "/panel/login")
    response.cookies["admin_token"] = .init(string: "", expires: Date(timeIntervalSince1970: 0))
    return response
  }
  
  @Sendable
  func home(req: Request) async throws -> View {
    try await req.view.render("/home")
  }
}
