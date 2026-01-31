# frozen_string_literal: true

class CreateGroupSteps < ActiveRecord::Migration[8.0]
  def change
    create_table(:group_steps) do |t|
      t.references(:group, null: false, foreign_key: true)
      t.references(:creator, null: false, foreign_key: { to_table: :users })
      t.string(:title, null: false)
      t.integer(:position, null: false)
      t.jsonb(:requirements, default: {}, null: false)
      t.references(:original_step, null: true, foreign_key: { to_table: :challenge_step_templates })

      t.timestamps
      t.datetime(:discarded_at)
    end

    add_index(:group_steps, :discarded_at)
    add_index(:group_steps, [:group_id, :position])
  end
end
