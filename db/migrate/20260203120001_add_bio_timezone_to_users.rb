# frozen_string_literal: true

class AddBioTimezoneToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column(:users, :bio, :text)
    add_column(:users, :timezone, :string, default: "UTC")
  end
end
