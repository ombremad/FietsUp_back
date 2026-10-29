//
//  CreateDangerActivityTriggers.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 02/10/2026.
//

import Fluent
import FluentMySQLDriver

struct CreateDangerActivityTriggers: AsyncMigration {
  func prepare(on database: any Database) async throws {
    guard let mysql = database as? any MySQLDatabase else { return }

    try await mysql.execute("""
    CREATE TRIGGER update_last_activity_on_new_danger_post
    AFTER INSERT ON danger_posts
    FOR EACH ROW
    BEGIN
        UPDATE danger_categories
        SET last_activity_date = NEW.creation_date
        WHERE id = NEW.id_danger_category;
    END
    """)

    try await mysql.execute("""
    CREATE TRIGGER update_last_activity_on_new_danger_comment
    AFTER INSERT ON danger_comments
    FOR EACH ROW
    BEGIN
        UPDATE danger_posts
        SET last_activity_date = NEW.creation_date
        WHERE id = NEW.id_danger_post;
    END
    """)

    try await mysql.execute("""
    CREATE TRIGGER cascade_last_activity_on_danger_post_update
    AFTER UPDATE ON danger_posts
    FOR EACH ROW
    BEGIN
        IF NOT (OLD.last_activity_date <=> NEW.last_activity_date) THEN
            UPDATE danger_categories
            SET last_activity_date = NEW.last_activity_date
            WHERE id = NEW.id_danger_category;
        END IF;
    END
    """)
  }

  func revert(on database: any Database) async throws {
    guard let mysql = database as? any MySQLDatabase else { return }
    try await mysql.execute("DROP TRIGGER IF EXISTS update_last_activity_on_new_danger_post")
    try await mysql.execute("DROP TRIGGER IF EXISTS update_last_activity_on_new_danger_comment")
    try await mysql.execute("DROP TRIGGER IF EXISTS cascade_last_activity_on_danger_post_update")
  }
}
