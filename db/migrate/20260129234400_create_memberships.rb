# frozen_string_literal: true

class CreateMemberships < ActiveRecord::Migration[8.0]
  def change
    create_table(:memberships) do |t|
      t.references(:user, null: false, foreign_key: true)
      t.references(:group, null: false, foreign_key: true)
      t.string(:role, null: false)
      t.string(:status, null: false)

      t.timestamps
    end

    add_index(:memberships, %i[user_id group_id], unique: true)
  end
end
