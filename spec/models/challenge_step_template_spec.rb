# frozen_string_literal: true

require "rails_helper"

RSpec.describe(ChallengeStepTemplate, type: :model) do
  let(:creator) { create(:user) }
  let(:challenge) { create(:challenge_template, creator: creator) }
  let(:group) { create(:group, challenge_template: challenge, creator: creator) }
  let(:group_step) { create(:group_step, group: group, original_step: step, creator: creator) }
  let(:step) { create(:challenge_step_template, challenge_template: challenge, creator: creator) }
  let(:step_without_title) { build(:challenge_step_template, challenge_template: challenge, title: nil, creator: creator) }
  let(:step_without_position) { build(:challenge_step_template, challenge_template: challenge, position: nil, creator: creator) }
  let(:step_without_challenge) { build(:challenge_step_template, challenge_template: nil, creator: creator) }
  let(:step_without_creator) { build(:challenge_step_template, challenge_template: challenge, creator: nil) }

  describe "validations" do
    it "validates presence of title" do
      expect(step_without_title).not_to(be_valid)
      expect(step_without_title.errors[:title]).to(include("can't be blank"))
    end

    it "validates presence of position" do
      expect(step_without_position).not_to(be_valid)
      expect(step_without_position.errors[:position]).to(include("can't be blank"))
    end

    it "validates presence of challenge_template" do
      expect(step_without_challenge).not_to(be_valid)
      expect(step_without_challenge.errors[:challenge_template]).to(include("must exist"))
    end

    it "validates presence of creator" do
      expect(step_without_creator).not_to(be_valid)
      expect(step_without_creator.errors[:creator]).to(include("must exist"))
    end
  end

  describe "associations" do
    it "belongs to challenge_template" do
      expect(step.challenge_template).to(eq(challenge))
    end

    it "belongs to creator" do
      expect(step.creator).to(eq(creator))
    end

    it "has many group_steps" do
      group_step
      expect(step.group_steps).to(include(group_step))
    end
  end

  describe "discard" do
    it "is discardable" do
      expect(step).not_to(be_discarded)
      step.discard
      expect(step).to(be_discarded)
      expect(described_class.kept).not_to(include(step))
    end
  end
end
