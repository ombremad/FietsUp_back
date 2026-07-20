//
//  WebPlaceController.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 20/07/2026.
//

import Fluent
import Vapor

struct WebPlaceController: RouteCollection {
  func boot(routes: any RoutesBuilder) throws {
    let places = routes
      .grouped("panel", "places")
      .grouped(PanelErrorMiddleware())
    let protected = places.grouped(PanelAuthMiddleware())
    
    protected.get(use: self.list)
    protected.get("new", use: self.new)
    protected.get(":placeID", use: self.detail)
    protected.post(use: self.create)
    protected.post(":placeID", use: self.update)
    protected.post(":placeID", "delete", use: self.delete)
  }
  
  @Sendable
  func list(req: Request) async throws -> View {
    let page = try await Place.query(on: req.db)
      .sort(\.$name)
      .with(\.$categories)
      .paginate(for: req)
    
    return try await req.view.render("panel/places/list", PageContext(page))
  }
  
  @Sendable
  func new(req: Request) async throws -> View {
    let allCategories = try await PlaceCategory.query(on: req.db)
      .sort(\.$name)
      .all()
        
    let categoryCheckboxes = try allCategories.map {
      Checkbox(id: try $0.requireID(), name: $0.name, isChecked: false)
    }
    
    struct NewPlaceContext: Encodable {
      let categoryCheckboxes: [Checkbox]
    }
    
    return try await req.view.render(
      "panel/places/new",
      NewPlaceContext(categoryCheckboxes: categoryCheckboxes)
    )
  }
  
  @Sendable
  func detail(req: Request) async throws -> View {
    let placeID = try req.parameters.require("placeID", as: UUID.self)
    guard let place = try await Place.query(on: req.db)
      .filter(\.$id == placeID)
      .with(\.$categories)
      .first()
    else {
      throw Abort(.notFound)
    }
    
    let allCategories = try await PlaceCategory.query(on: req.db)
      .sort(\.$name)
      .all()
    
    let placeCategoryIDs = Set(try place.categories.map { try $0.requireID() })
    
    let categoryCheckboxes = try allCategories.map {
      Checkbox(id: try $0.requireID(), name: $0.name, isChecked: placeCategoryIDs.contains(try $0.requireID()))
    }
    
    struct PlaceDetailContext: Encodable {
      let place: Place
      let categoryCheckboxes: [Checkbox]
    }
    
    return try await req.view.render(
      "panel/places/detail",
      PlaceDetailContext(place: place, categoryCheckboxes: categoryCheckboxes)
    )
  }
  
  @Sendable
  func create(req: Request) async throws -> Response {
    try stripEmptyFormFields(from: req)
    try CreatePlaceDTO.validate(content: req)
    let dto = try req.content.decode(CreatePlaceDTO.self)
    
    let place = Place(from: dto)
    try await place.save(on: req.db)
    
    let categories = try await PlaceCategory.query(on: req.db)
      .filter(\.$id ~~ dto.categoriesIds)
      .all()
    try await place.$categories.attach(categories, on: req.db)
    
    let placeID = try place.requireID()
    return req.redirect(to: "/panel/places/\(placeID)")
  }
  
  @Sendable
  func update(req: Request) async throws -> Response {
    let placeID = try req.parameters.require("placeID", as: UUID.self)
    guard let place = try await Place.find(placeID, on: req.db) else {
      throw Abort(.notFound)
    }
    
    try PatchPlaceDTO.validate(content: req)
    let dto = try req.content.decode(PatchPlaceDTO.self)
    
    place.patch(with: dto)
    try await place.save(on: req.db)
    
    if let categoriesIds = dto.categoriesIds {
      let categories = try await PlaceCategory.query(on: req.db)
        .filter(\.$id ~~ categoriesIds)
        .all()
      try await place.$categories.detachAll(on: req.db)
      try await place.$categories.attach(categories, on: req.db)
    }
    
    return req.redirect(to: "/panel/places/\(placeID)")
  }
  
  @Sendable
  func delete(req: Request) async throws -> Response {
    let placeID = try req.parameters.require("placeID", as: UUID.self)
    guard let place = try await Place.find(placeID, on: req.db) else {
      throw Abort(.notFound)
    }
    
    try await place.delete(on: req.db)
    return req.redirect(to: "/panel/places")
  }
}
