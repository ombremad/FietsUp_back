//
//  GetTokenDTO.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 17/02/2026.
//

import Vapor
import Fluent

struct GetTokenDTO: Content {
    let token: String
    
    init(_ token: String) {
        self.token = token
    }
}
