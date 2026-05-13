//
//  GetTokenDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 17/02/2026.
//

import Vapor

struct GetAuthDTO: Content {
  let token: String
  let user: GetUserDTO

  init(token: String, user: User) throws {
    self.token = token
    self.user = try GetUserDTO(from: user)
  }
}
