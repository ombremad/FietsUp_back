//
//  CreateLocationTriggers.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 02/10/2026.
//

import Fluent
import FluentMySQLDriver

struct CreateLocationTriggers: AsyncMigration {
  func prepare(on database: any Database) async throws {
    guard let mysql = database as? any MySQLDatabase else { return }

    try await mysql.execute("""
    CREATE TRIGGER places_location_insert
    BEFORE INSERT ON places
    FOR EACH ROW
    BEGIN
      SET NEW.location = ST_GeomFromText(
        CONCAT('POINT(', NEW.longitude, ' ', NEW.latitude, ')'), 4326
      );
    END
    """)

    try await mysql.execute("""
    CREATE TRIGGER places_location_update
    BEFORE UPDATE ON places
    FOR EACH ROW
    BEGIN
      IF NEW.latitude != OLD.latitude OR NEW.longitude != OLD.longitude THEN
        SET NEW.location = ST_GeomFromText(
          CONCAT('POINT(', NEW.longitude, ' ', NEW.latitude, ')'), 4326
        );
      END IF;
    END
    """)

    try await mysql.execute("""
    CREATE TRIGGER danger_posts_location_insert
    BEFORE INSERT ON danger_posts
    FOR EACH ROW
    BEGIN
      SET NEW.location = ST_GeomFromText(
        CONCAT('POINT(', NEW.longitude, ' ', NEW.latitude, ')'), 4326
      );
    END
    """)

    try await mysql.execute("""
    CREATE TRIGGER danger_posts_location_update
    BEFORE UPDATE ON danger_posts
    FOR EACH ROW
    BEGIN
      IF NEW.latitude != OLD.latitude OR NEW.longitude != OLD.longitude THEN
        SET NEW.location = ST_GeomFromText(
          CONCAT('POINT(', NEW.longitude, ' ', NEW.latitude, ')'), 4326
        );
      END IF;
    END
    """)
  }

  func revert(on database: any Database) async throws {
    guard let mysql = database as? any MySQLDatabase else { return }
    try await mysql.execute("DROP TRIGGER IF EXISTS places_location_insert")
    try await mysql.execute("DROP TRIGGER IF EXISTS places_location_update")
    try await mysql.execute("DROP TRIGGER IF EXISTS danger_posts_location_insert")
    try await mysql.execute("DROP TRIGGER IF EXISTS danger_posts_location_update")
  }
}
