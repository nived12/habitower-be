# frozen_string_literal: true

class CreateReactions < ActiveRecord::Migration[8.0]
  def change
    create_table(:reactions) do |t|
      t.references(:user, null: false, foreign_key: true)
      t.references(:progress_log, null: false, foreign_key: true)
      t.string(:kind, null: false, default: "high_five")
      t.timestamps
    end

    add_index(:reactions, [:user_id, :progress_log_id, :kind], unique: true)
  end
end
