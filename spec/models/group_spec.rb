# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Group, type: :model) do
  let(:creator) { create(:user) }
  let(:challenge) { create(:challenge, creator: creator) }
  let(:group) { create(:group, challenge: challenge, creator: creator) }
  let(:membership) { create(:membership, user: creator, group: group) }

  describe "validations" do
    it "validates presence of start_date" do
      invalid = build(:group, challenge: challenge, creator: creator, start_date: nil)
      expect(invalid).not_to(be_valid)
      expect(invalid.errors[:start_date]).to(include("can't be blank"))
    end

    it "validates presence of challenge" do
      invalid = build(:group, challenge: nil, creator: creator)
      expect(invalid).not_to(be_valid)
      expect(invalid.errors[:challenge]).to(include("must exist"))
    end

    it "validates presence of creator" do
      invalid = build(:group, challenge: challenge, creator: nil)
      expect(invalid).not_to(be_valid)
      expect(invalid.errors[:creator]).to(include("must exist"))
    end
  end

  describe "associations" do
    it "belongs to challenge" do
      expect(group.challenge).to(eq(challenge))
    end

    it "belongs to creator" do
      expect(group.creator).to(eq(creator))
    end

    it "has many memberships" do
      expect(group.memberships).to(include(membership))
    end

    it "has many users through memberships" do
      membership
      expect(group.users).to(include(creator))
    end
  end

  describe "enums" do
    it "defines privacy_type with public and private" do
      expect(group).to(respond_to(:privacy_type_public?))
      expect(group).to(respond_to(:privacy_type_private?))
    end

    it "defaults privacy_type to public" do
      expect(group.privacy_type).to(eq("public"))
      expect(group.privacy_type_public?).to(be(true))
    end
  end

  describe "discard" do
    it "is discardable" do
      expect(group).not_to(be_discarded)
      group.discard
      expect(group).to(be_discarded)
      expect(described_class.kept).not_to(include(group))
    end

    it "discards associated memberships when discarded" do
      membership
      group.discard
      expect(membership.reload).to(be_discarded)
    end
  end
end
