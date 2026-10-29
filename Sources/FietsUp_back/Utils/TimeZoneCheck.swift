//
//  TimeZoneCheck.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 29/10/2026.
//

import SQLKit
import Vapor

/// Logs an error at boot when the database session isn't in UTC, since TIMESTAMP columns are converted using it.
struct TimeZoneCheck: LifecycleHandler {
  func didBootAsync(_ application: Application) async throws {
    guard let sql = application.db as? any SQLDatabase else { return }
    struct Row: Decodable { let utc_offset: Int }

    do {
      let row = try await sql.raw("SELECT TIME_TO_SEC(TIMEDIFF(NOW(), UTC_TIMESTAMP())) AS utc_offset")
        .first(decoding: Row.self)
      if let offset = row?.utc_offset, offset != 0 {
        application.logger.error(
          "Database time zone is not UTC (offset: \(offset) s). Set default-time-zone = '+00:00' on the database server."
        )
      }
    } catch {
      application.logger.warning("Could not check the database time zone: \(error)")
    }
  }
}
