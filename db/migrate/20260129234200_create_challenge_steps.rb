# frozen_string_literal: true

class CreateChallengeSteps < ActiveRecord::Migration[8.0]
  def change
    create_table(:challenge_steps) do |t|
      t.references(:challenge, null: false, foreign_key: true)
      t.references(:creator, null: false, foreign_key: { to_table: :users })
      t.string(:title, null: false)
      t.integer(:position, null: false)
      t.jsonb(:requirements, default: {}, null: false)

      t.timestamps
    end
  end
end
