# frozen_string_literal: true

class CreateProgressLogs < ActiveRecord::Migration[8.0]
  def change
    create_table(:progress_logs) do |t|
      t.references(:membership, null: false, foreign_key: true)
      t.references(:challenge_step, null: false, foreign_key: true)
      t.decimal(:value, precision: 15, scale: 4, null: false)
      t.datetime(:occurred_at, null: false)
      t.text(:note)
      t.string(:proof_url)

      t.timestamps
    end
  end
end
