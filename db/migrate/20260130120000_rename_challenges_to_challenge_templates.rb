# frozen_string_literal: true

class RenameChallengesToChallengeTemplates < ActiveRecord::Migration[8.0]
  def change
    remove_foreign_key(:groups, :challenges)
    rename_table(:challenges, :challenge_templates)
    rename_column(:groups, :challenge_id, :challenge_template_id)
    add_foreign_key(:groups, :challenge_templates, column: :challenge_template_id)
    add_column(:groups, :rules, :jsonb, default: {}, null: false)
    add_column(:groups, :integrity_score, :decimal, precision: 5, scale: 2, default: 100.0, null: false)
  end
end
