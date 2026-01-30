# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Challenge, type: :model) do
  let(:creator) { create(:user) }
  let(:challenge) { create(:challenge, creator: creator) }
  let(:challenge_without_title) { build(:challenge, title: nil, creator: creator) }
  let(:challenge_without_creator) { build(:challenge, title: "Test", creator: nil) }
  let(:step) { create(:challenge_step, challenge: challenge, creator: creator) }
  let(:group) { create(:group, challenge: challenge, creator: creator) }

  describe "validations" do
    it "validates presence of title" do
      expect(challenge_without_title).not_to(be_valid)
      expect(challenge_without_title.errors[:title]).to(include("can't be blank"))
    end

    it "validates presence of creator" do
      expect(challenge_without_creator).not_to(be_valid)
      expect(challenge_without_creator.errors[:creator]).to(include("must exist"))
    end
  end

  describe "associations" do
    it "belongs to creator" do
      expect(challenge.creator).to(eq(creator))
    end

    it "has many challenge_steps" do
      expect(challenge.challenge_steps).to(include(step))
    end

    it "has many groups" do
      expect(challenge.groups).to(include(group))
    end
  end

  describe "enums" do
    it "defines period_type with weekly and monthly" do
      expect(challenge).to(respond_to(:weekly?))
      expect(challenge).to(respond_to(:monthly?))
    end

    it "defaults period_type to weekly" do
      expect(challenge.period_type).to(eq("weekly"))
      expect(challenge.weekly?).to(be(true))
    end
  end

  describe "discard" do
    it "is discardable" do
      expect(challenge).not_to(be_discarded)
      challenge.discard
      expect(challenge).to(be_discarded)
      expect(described_class.kept).not_to(include(challenge))
      expect(described_class.discarded).to(include(challenge))
    end

    it "discards associated challenge_steps and groups when discarded" do
      step
      group
      challenge.discard
      expect(step.reload).to(be_discarded)
      expect(group.reload).to(be_discarded)
    end
  end
end
