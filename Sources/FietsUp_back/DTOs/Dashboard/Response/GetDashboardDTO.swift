//
//  GetDashboardDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 17/04/2026.
//

import Vapor

struct GetDashboardDTO: Content {
  var user: GetUserDTO
}

extension GetDashboardDTO {
  init(user: User) throws {
    
    self.init(
      user: try GetUserDTO(from: user)
    )
  }
}
