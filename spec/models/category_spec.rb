# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Category, type: :model) do
  describe "validations" do
    let(:category) { build(:category, name: "Fitness", slug: "fitness") }

    it "validates presence of name" do
      category.name = nil
      expect(category).not_to(be_valid)
      expect(category.errors[:name]).to(include("can't be blank"))
    end

    it "validates presence of slug" do
      category.slug = nil
      expect(category).not_to(be_valid)
      expect(category.errors[:slug]).to(include("can't be blank"))
    end

    it "validates uniqueness of slug" do
      create(:category, slug: "fitness")
      duplicate = build(:category, slug: "fitness")
      expect(duplicate).not_to(be_valid)
      expect(duplicate.errors[:slug]).to(include("has already been taken"))
    end
  end

  describe "associations" do
    let(:category) { create(:category) }
    let(:challenge_template) { create(:challenge_template) }

    it "has many challenge_templates through challenge_template_categories" do
      challenge_template.categories << category
      expect(category.challenge_templates).to(include(challenge_template))
    end
  end
end
