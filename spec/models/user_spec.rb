# frozen_string_literal: true

require "rails_helper"

RSpec.describe(User, type: :model) do
  describe "validations" do
    let(:user_without_email) { build(:user, email: nil) }

    it "validates presence of email" do
      expect(user_without_email).not_to(be_valid)
      expect(user_without_email.errors[:email]).to(include("can't be blank"))
    end

    it "validates uniqueness of email" do
      create(:user, email: "same@example.com")
      duplicate = build(:user, email: "same@example.com")
      expect(duplicate).not_to(be_valid)
      expect(duplicate.errors[:email]).to(be_present)
    end
  end

  describe "associations" do
    let(:user) { create(:user) }
    let(:challenge) { create(:challenge, creator: user) }
    let(:group) { create(:group, challenge: create(:challenge, creator: user), creator: user) }
    let(:membership) { create(:membership, user: user, group: group) }

    it "has many created_challenges" do
      expect(user.created_challenges).to(include(challenge))
    end

    it "has many memberships" do
      expect(user.memberships).to(include(membership))
    end

    it "has many groups through memberships" do
      membership
      expect(user.groups).to(include(group))
    end
  end

  describe "creation" do
    let(:user) { build(:user, email: "new@example.com", password: "password123", password_confirmation: "password123") }

    it "creates a valid user with email and password" do
      expect(user).to(be_valid)
      expect(user.save).to(be(true))
    end
  end
end
