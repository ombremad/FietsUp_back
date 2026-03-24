//
//  GetTokenDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 17/02/2026.
//

import Fluent
import Vapor

struct GetTokenDTO: Content {
  let token: String

  init(_ token: String) {
    self.token = token
  }
}
