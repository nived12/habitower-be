# frozen_string_literal: true

class PointProgressLogsToGroupSteps < ActiveRecord::Migration[8.0]
  def up
    add_reference(:progress_logs, :group_step, null: true, foreign_key: true)

    execute(<<-SQL.squish)
      UPDATE progress_logs pl
      SET group_step_id = (
        SELECT gs.id FROM group_steps gs
        INNER JOIN memberships m ON m.group_id = gs.group_id
        WHERE m.id = pl.membership_id AND gs.original_step_id = pl.challenge_step_id
        LIMIT 1
      )
      WHERE pl.group_step_id IS NULL
    SQL

    remove_foreign_key(:progress_logs, :challenge_step_templates, column: :challenge_step_id)
    remove_column(:progress_logs, :challenge_step_id)
    change_column_null(:progress_logs, :group_step_id, false)
  end

  def down
    add_reference(:progress_logs, :challenge_step, null: true, foreign_key: { to_table: :challenge_step_templates })
    # Backfill would require mapping group_step_id -> original_step_id per membership's group; omitted for brevity
    remove_foreign_key(:progress_logs, :group_steps)
    remove_column(:progress_logs, :group_step_id)
    change_column_null(:progress_logs, :challenge_step_id, false)
  end
end
