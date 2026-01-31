# frozen_string_literal: true

class CopyTemplateStepsToGroupSteps < ActiveRecord::Migration[8.0]
  def up
    execute(<<-SQL.squish)
      INSERT INTO group_steps (group_id, creator_id, title, position, requirements, original_step_id, created_at, updated_at, discarded_at)
      SELECT g.id, g.creator_id, cst.title, cst.position, cst.requirements, cst.id, NOW(), NOW(), cst.discarded_at
      FROM groups g
      INNER JOIN challenge_step_templates cst ON cst.challenge_template_id = g.challenge_template_id
      ORDER BY g.id, cst.position
    SQL
  end

  def down
    execute("DELETE FROM group_steps")
  end
end
