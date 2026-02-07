# frozen_string_literal: true

class CreateChallengeTemplateCategories < ActiveRecord::Migration[8.0]
  def change
    create_table(:challenge_template_categories) do |t|
      t.references(:challenge_template, null: false, foreign_key: true)
      t.references(:category, null: false, foreign_key: true)
      t.timestamps
    end

    add_index(
      :challenge_template_categories,
      [:challenge_template_id, :category_id],
      unique: true,
      name: "idx_template_categories_unique"
    )
  end
end
