# frozen_string_literal: true

class AddDiscardedAtToDiscardables < ActiveRecord::Migration[8.0]
  def change
    tables = %i[challenges groups memberships challenge_steps progress_logs]
    tables.each do |table|
      add_column(table, :discarded_at, :datetime)
      add_index(table, :discarded_at)
    end
  end
end
