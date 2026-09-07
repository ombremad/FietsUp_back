//
//  Checkbox.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 20/07/2026.
//

import Foundation

struct Checkbox: Encodable {
  let id: UUID
  let name: String
  let isChecked: Bool
}
