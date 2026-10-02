//
//  CreateActivityDistanceTriggers.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 02/10/2026.
//

import Fluent
import SQLKit

struct CreateActivityDistanceTriggers: AsyncMigration {
  func prepare(on database: any Database) async throws {
    guard let sql = database as? any SQLDatabase else { return }
    try await sql.raw("""
    CREATE TRIGGER update_total_elapsed_distance_on_new_activity
    AFTER INSERT ON activities
    FOR EACH ROW
    BEGIN
        UPDATE users
        SET total_elapsed_distance = total_elapsed_distance + NEW.distance
        WHERE id = NEW.id_user;
    END
    """).run()

    try await sql.raw("""
    CREATE TRIGGER update_total_elapsed_distance_on_delete_activity
    AFTER DELETE ON activities
    FOR EACH ROW
    BEGIN
        UPDATE users
        SET total_elapsed_distance = total_elapsed_distance - OLD.distance
        WHERE id = OLD.id_user;
    END
    """).run()
  }

  func revert(on database: any Database) async throws {
    guard let sql = database as? any SQLDatabase else { return }
    try await sql.raw("DROP TRIGGER IF EXISTS update_total_elapsed_distance_on_new_activity").run()
    try await sql.raw("DROP TRIGGER IF EXISTS update_total_elapsed_distance_on_delete_activity").run()
  }
}
