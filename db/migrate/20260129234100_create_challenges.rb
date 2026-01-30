# frozen_string_literal: true

class CreateChallenges < ActiveRecord::Migration[8.0]
  def change
    create_table(:challenges) do |t|
      t.string(:title, null: false)
      t.text(:description)
      t.string(:period_type, null: false)
      t.jsonb(:rules, default: {}, null: false)
      t.references(:creator, null: false, foreign_key: { to_table: :users })

      t.timestamps
    end
  end
end
