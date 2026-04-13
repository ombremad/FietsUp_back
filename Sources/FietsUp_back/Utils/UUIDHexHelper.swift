//
//  UUIDHexHelper.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 13/04/2026.
//

import Foundation

extension UUID {
  var hexString: String {
    uuidString.replacingOccurrences(of: "-", with: "")
  }
  
  init?(hex: String) {
    let s = hex
    self.init(uuidString: "\(s.prefix(8))-\(s.dropFirst(8).prefix(4))-\(s.dropFirst(12).prefix(4))-\(s.dropFirst(16).prefix(4))-\(s.dropFirst(20))")
  }
}
