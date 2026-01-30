# frozen_string_literal: true

class SetDefaultValuesForEnums < ActiveRecord::Migration[8.0]
  def change
    change_column_default(:challenges, :period_type, from: nil, to: "weekly")
    change_column_default(:groups, :privacy_type, from: nil, to: "public")
    change_column_default(:memberships, :role, from: nil, to: "member")
    change_column_default(:memberships, :status, from: nil, to: "active")
  end
end
