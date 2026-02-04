# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Follow, type: :model) do
  describe "validations" do
    let(:user) { create(:user) }

    it "validates uniqueness of follower_id scoped to followed_id" do
      followed = create(:user)
      create(:follow, follower: user, followed: followed)
      duplicate = build(:follow, follower: user, followed: followed)
      expect(duplicate).not_to(be_valid)
      expect(duplicate.errors[:follower_id]).to(be_present)
    end

    it "does not allow following self" do
      follow = build(:follow, follower: user, followed: user)
      expect(follow).not_to(be_valid)
      expect(follow.errors[:followed_id]).to(include("cannot follow yourself"))
    end
  end

  describe "associations" do
    let(:follower) { create(:user) }
    let(:followed) { create(:user) }
    let(:follow) { create(:follow, follower: follower, followed: followed) }

    it "belongs to follower" do
      expect(follow.follower).to(eq(follower))
    end

    it "belongs to followed" do
      expect(follow.followed).to(eq(followed))
    end
  end
end
