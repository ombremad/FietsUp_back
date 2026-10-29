//
//  CreateForumActivityTriggers.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 02/10/2026.
//

import Fluent
import FluentMySQLDriver

struct CreateForumActivityTriggers: AsyncMigration {
  func prepare(on database: any Database) async throws {
    guard let mysql = database as? any MySQLDatabase else { return }

    try await mysql.execute("""
    CREATE TRIGGER update_last_activity_on_new_forum_post
    AFTER INSERT ON forum_posts
    FOR EACH ROW
    BEGIN
        UPDATE forum_categories
        SET last_activity_date = NEW.creation_date
        WHERE id = NEW.id_forum_category;
    END
    """)

    try await mysql.execute("""
    CREATE TRIGGER update_last_activity_on_new_forum_comment
    AFTER INSERT ON forum_comments
    FOR EACH ROW
    BEGIN
        UPDATE forum_posts
        SET last_activity_date = NEW.creation_date
        WHERE id = NEW.id_forum_post;
    END
    """)

    try await mysql.execute("""
    CREATE TRIGGER cascade_last_activity_on_forum_post_update
    AFTER UPDATE ON forum_posts
    FOR EACH ROW
    BEGIN
        IF NOT (OLD.last_activity_date <=> NEW.last_activity_date) THEN
            UPDATE forum_categories
            SET last_activity_date = NEW.last_activity_date
            WHERE id = NEW.id_forum_category;
        END IF;
    END
    """)
  }

  func revert(on database: any Database) async throws {
    guard let mysql = database as? any MySQLDatabase else { return }
    try await mysql.execute("DROP TRIGGER IF EXISTS update_last_activity_on_new_forum_post")
    try await mysql.execute("DROP TRIGGER IF EXISTS update_last_activity_on_new_forum_comment")
    try await mysql.execute("DROP TRIGGER IF EXISTS cascade_last_activity_on_forum_post_update")
  }
}
