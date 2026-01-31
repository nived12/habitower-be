# frozen_string_literal: true

class RenameChallengeStepsToChallengeStepTemplates < ActiveRecord::Migration[8.0]
  def change
    remove_foreign_key(:challenge_steps, :challenge_templates)
    rename_table(:challenge_steps, :challenge_step_templates)
    rename_column(:challenge_step_templates, :challenge_id, :challenge_template_id)
    add_foreign_key(:challenge_step_templates, :challenge_templates, column: :challenge_template_id)
  end
end
