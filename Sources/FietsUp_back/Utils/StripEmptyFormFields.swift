//
//  StripEmptyFormFields.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 20/07/2026.
//

import Vapor

func stripEmptyFormFields(from req: Request) throws {
  guard var body = try? req.content.decode([String: String].self) else { return }
  body = body.filter { !$0.value.isEmpty }
  try req.content.encode(body, as: .urlEncodedForm)
}
