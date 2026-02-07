# frozen_string_literal: true

class AddTitleToGroups < ActiveRecord::Migration[8.0]
  def change
    add_column(:groups, :title, :string)
  end
end
