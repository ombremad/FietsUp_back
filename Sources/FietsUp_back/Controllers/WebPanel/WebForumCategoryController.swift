//
//  WebForumCategoryController.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 20/07/2026.
//

import Fluent
import Vapor

struct WebForumCategoryController: RouteCollection {
  func boot(routes: any RoutesBuilder) throws {
    let categories = routes
      .grouped("panel", "forum", "categories")
      .grouped(PanelErrorMiddleware())
    let protected = categories.grouped(PanelAuthMiddleware())
    
    protected.get(use: self.list)
    protected.get("new", use: self.new)
    protected.get(":categoryID", use: self.detail)
    protected.post(use: self.create)
    protected.post(":categoryID", use: self.update)
    protected.post(":categoryID", "delete", use: self.delete)
  }
  
  @Sendable
  func list(req: Request) async throws -> View {
    let page = try await ForumCategory.query(on: req.db)
      .sort(\.$name)
      .with(\.$forumPosts)
      .paginate(for: req)
    
    return try await req.view.render("panel/forum/categories/list", PageContext(page))
  }
  
  @Sendable
  func new(req: Request) async throws -> View {
    try await req.view.render("panel/forum/categories/new")
  }
  
  @Sendable
  func detail(req: Request) async throws -> View {
    let categoryID = try req.parameters.require("categoryID", as: UUID.self)
    guard let category = try await ForumCategory.query(on: req.db)
      .filter(\.$id == categoryID)
      .with(\.$forumPosts)
      .first()
    else {
      throw Abort(.notFound)
    }
    
    return try await req.view.render("panel/forum/categories/detail", ["category": category])
  }
  
  @Sendable
  func create(req: Request) async throws -> Response {
    try stripEmptyFormFields(from: req)
    try CreateForumCategoryDTO.validate(content: req)
    let dto = try req.content.decode(CreateForumCategoryDTO.self)
    
    let category = ForumCategory(from: dto)
    try await category.save(on: req.db)
    
    let categoryID = try category.requireID()
    return req.redirect(to: "/panel/forum/categories/\(categoryID)")
  }
  
  @Sendable
  func update(req: Request) async throws -> Response {
    let categoryID = try req.parameters.require("categoryID", as: UUID.self)
    guard let category = try await ForumCategory.find(categoryID, on: req.db) else {
      throw Abort(.notFound)
    }
    
    try PatchForumCategoryDTO.validate(content: req)
    let dto = try req.content.decode(PatchForumCategoryDTO.self)
    
    category.patch(with: dto)
    try await category.save(on: req.db)
    
    return req.redirect(to: "/panel/forum/categories/\(categoryID)")
  }
  
  @Sendable
  func delete(req: Request) async throws -> Response {
    let categoryID = try req.parameters.require("categoryID", as: UUID.self)
    guard let category = try await ForumCategory.find(categoryID, on: req.db) else {
      throw Abort(.notFound)
    }
    
    try await category.delete(on: req.db)
    return req.redirect(to: "/panel/forum/categories")
  }
}
