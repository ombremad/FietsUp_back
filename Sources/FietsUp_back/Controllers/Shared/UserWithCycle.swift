//
//  WithCycle.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 04/05/2026.
//

import Vapor
import Fluent

extension EagerLoadBuilder where Model == User {
  @discardableResult
  func withCycle() -> Self {
    self.with(\.$cycleColor)
      .with(\.$cycleType)
      .with(\.$cycleDecoration)
  }
}
