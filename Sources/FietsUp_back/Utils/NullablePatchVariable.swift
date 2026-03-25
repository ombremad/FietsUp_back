//
//  NullablePatchVariable.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 25/03/2026.
//

extension KeyedDecodingContainer {
  func decodeNullablePatchVariable<T: Decodable>(_ type: T.Type, forKey: Key) throws -> T?? {
    guard contains(forKey) else { return nil }
    return try decodeIfPresent(T.self, forKey: forKey)
  }
}
