//
//  ReturnOrFail.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 27/03/2026.
//

import Vapor

func returnOrFail<T>(_ value: T?) throws -> T {
  guard let value else {
    let type = String(describing: T.self)
    throw Abort(.notFound, reason: type + " not found")
  }
  return value
}
