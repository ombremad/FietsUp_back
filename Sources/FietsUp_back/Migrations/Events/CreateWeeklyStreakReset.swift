//
//  CreateWeeklyStreakReset.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 02/10/2026.
//

import Fluent
import FluentMySQLDriver

struct CreateWeeklyStreakReset: AsyncMigration {
  func prepare(on database: any Database) async throws {
    guard let mysql = database as? any MySQLDatabase else { return }

    try await mysql.execute("SET GLOBAL event_scheduler = ON")

    try await mysql.execute("""
    CREATE PROCEDURE reset_streaks()
    BEGIN
    UPDATE users u
    LEFT JOIN (
        SELECT id_user, COUNT(*) AS recent_activity
        FROM activities
        WHERE start_date >= CURDATE() - INTERVAL 7 DAY
        GROUP BY id_user
    ) a ON a.id_user = u.id
    SET
        u.streak = CASE
            WHEN a.recent_activity IS NULL THEN 0
            ELSE u.streak
        END,
        u.streak_updated_this_week = 0;
    END
    """)

    try await mysql.execute("""
    CREATE EVENT weekly_streak_update
    ON SCHEDULE EVERY 7 DAY
    STARTS (
      TIMESTAMP(DATE_ADD(
        CURDATE(),
        INTERVAL (7 - WEEKDAY(CURDATE())) % 7 DAY
      ), '00:01:00')
    )
    DO CALL reset_streaks()
    """)
  }

  func revert(on database: any Database) async throws {
    guard let mysql = database as? any MySQLDatabase else { return }
    try await mysql.execute("DROP EVENT IF EXISTS weekly_streak_update")
    try await mysql.execute("DROP PROCEDURE IF EXISTS reset_streaks")
  }
}
