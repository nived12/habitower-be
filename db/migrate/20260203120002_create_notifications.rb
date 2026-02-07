# frozen_string_literal: true

class CreateNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table(:notifications) do |t|
      t.references(:recipient, null: false, foreign_key: { to_table: :users })
      t.references(:actor, null: true, foreign_key: { to_table: :users })
      t.string(:action, null: false)
      t.references(:notifiable, polymorphic: true)
      t.datetime(:read_at)
      t.jsonb(:data, default: {})
      t.timestamps
    end

    add_index(:notifications, [:recipient_id, :read_at])
  end
end
