# frozen_string_literal: true

class CreateGroups < ActiveRecord::Migration[8.0]
  def change
    create_table(:groups) do |t|
      t.references(:challenge, null: false, foreign_key: true)
      t.references(:creator, null: false, foreign_key: { to_table: :users })
      t.date(:start_date, null: false)
      t.string(:privacy_type, null: false)
      t.string(:invite_code)

      t.timestamps
    end

    add_index(:groups, :invite_code)
  end
end
