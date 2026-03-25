//
//  ActivityController.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 24/03/2026.
//

import Fluent
import Vapor

struct ActivityController: RouteCollection {
  func boot(routes: any RoutesBuilder) throws {

    let request = routes.grouped("activities")
    let userProtected =
      request
      .grouped(JWTMiddleware())
      .groupedOpenAPI(auth: .bearer(id: "BearerAuth", format: "JWT"))

    userProtected.post(use: self.create)
      .openAPI(
        tags: "Activities",
        summary: "Create",
        description: "Create a new activity for current user",
        body: .type(CreateActivityDTO.self),
        response: .type(GetActivityDTO.self)
      )
    userProtected.get(use: self.getAllForUser)
      .openAPI(
        tags: "Activities",
        summary: "List",
        description: "Get all activities for current user",
        response: .type([GetActivityDTO].self),
      )
    userProtected.delete(":id", use: self.deleteById)
      .openAPI(
        tags: "Activities",
        summary: "Delete",
        description: "Delete an activity belonging to user",
        response: .type(HTTPStatus.self),
      )
  }

  @Sendable
  func create(req: Request) async throws -> GetActivityDTO {
    let user = try await req.requireUser()
    let userID = try user.requireID()
    try CreateActivityDTO.validate(content: req)
    let dto = try req.content.decode(CreateActivityDTO.self)
    
    guard dto.endDate > dto.startDate else {
      throw Abort(.badRequest, reason: "endDate must be after startDate")
    }
    guard dto.endDate <= Date.now else {
      throw Abort(.badRequest, reason: "endDate must not be in the future")
    }
    
    let activity = Activity(from: dto, userID: userID)
    try await activity.save(on: req.db)
    return try GetActivityDTO(from: activity)
  }

  @Sendable
  func getAllForUser(req: Request) async throws -> [GetActivityDTO] {
    let user = try await req.requireUser()
    let userID = try user.requireID()
    
    let activities = try await Activity.query(on: req.db)
      .filter(\.$user.$id == userID)
      .sort(\.$endDate, .descending)
      .all()
    return try activities.map { activity in
      try GetActivityDTO(from: activity)
    }
  }

  @Sendable
  func deleteById(req: Request) async throws -> HTTPStatus {
    let id = try req.parameters.require("id", as: UUID.self)
    let activity = try await find(id: id, on: req.db)
    
    let user = try await req.requireUser()
    let userID = try user.requireID()
    guard activity.$user.id == userID else {
      throw Abort(.notFound)
    }
    
    try await activity.delete(on: req.db)
    return .noContent
  }
  
  private func find(id: UUID, on db: any Database) async throws -> Activity {
    guard
      let activity = try await Activity.query(on: db)
        .filter(\.$id == id)
        .first()
    else {
      throw Abort(.notFound)
    }
    return activity
  }
}
