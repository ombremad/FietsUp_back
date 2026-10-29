//
//  CreateActivityDistanceTriggers.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 02/10/2026.
//

import Fluent
import FluentMySQLDriver

struct CreateActivityDistanceTriggers: AsyncMigration {
  func prepare(on database: any Database) async throws {
    guard let mysql = database as? any MySQLDatabase else { return }
    try await mysql.execute("""
    CREATE TRIGGER update_total_elapsed_distance_on_new_activity
    AFTER INSERT ON activities
    FOR EACH ROW
    BEGIN
        UPDATE users
        SET total_elapsed_distance = total_elapsed_distance + NEW.distance
        WHERE id = NEW.id_user;
    END
    """)

    try await mysql.execute("""
    CREATE TRIGGER update_total_elapsed_distance_on_delete_activity
    AFTER DELETE ON activities
    FOR EACH ROW
    BEGIN
        UPDATE users
        SET total_elapsed_distance = total_elapsed_distance - OLD.distance
        WHERE id = OLD.id_user;
    END
    """)
  }

  func revert(on database: any Database) async throws {
    guard let mysql = database as? any MySQLDatabase else { return }
    try await mysql.execute("DROP TRIGGER IF EXISTS update_total_elapsed_distance_on_new_activity")
    try await mysql.execute("DROP TRIGGER IF EXISTS update_total_elapsed_distance_on_delete_activity")
  }
}
