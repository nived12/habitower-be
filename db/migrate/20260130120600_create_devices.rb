# frozen_string_literal: true

class CreateDevices < ActiveRecord::Migration[8.0]
  def change
    create_table :devices do |t|
      t.references :user, null: false, foreign_key: true
      t.string :platform, null: false
      t.string :token, null: false

      t.timestamps
    end

    add_index :devices, [:user_id, :platform], unique: true
  end
end
