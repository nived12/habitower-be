# frozen_string_literal: true

require "rails_helper"

RSpec.describe(ChallengeStep, type: :model) do
  let(:creator) { create(:user) }
  let(:challenge) { create(:challenge, creator: creator) }
  let(:group) { create(:group, challenge: challenge, creator: creator) }
  let(:membership) { create(:membership, user: creator, group: group) }
  let(:step) { create(:challenge_step, challenge: challenge, creator: creator) }
  let(:step_without_title) { build(:challenge_step, challenge: challenge, title: nil, creator: creator) }
  let(:step_without_position) { build(:challenge_step, challenge: challenge, position: nil, creator: creator) }
  let(:step_without_challenge) { build(:challenge_step, challenge: nil, creator: creator) }
  let(:step_without_creator) { build(:challenge_step, challenge: challenge, creator: nil) }
  let(:log) { create(:progress_log, membership: membership, challenge_step: step) }

  describe "validations" do
    it "validates presence of title" do
      expect(step_without_title).not_to(be_valid)
      expect(step_without_title.errors[:title]).to(include("can't be blank"))
    end

    it "validates presence of position" do
      expect(step_without_position).not_to(be_valid)
      expect(step_without_position.errors[:position]).to(include("can't be blank"))
    end

    it "validates presence of challenge" do
      expect(step_without_challenge).not_to(be_valid)
      expect(step_without_challenge.errors[:challenge]).to(include("must exist"))
    end

    it "validates presence of creator" do
      expect(step_without_creator).not_to(be_valid)
      expect(step_without_creator.errors[:creator]).to(include("must exist"))
    end
  end

  describe "associations" do
    it "belongs to challenge" do
      expect(step.challenge).to(eq(challenge))
    end

    it "belongs to creator" do
      expect(step.creator).to(eq(creator))
    end

    it "has many progress_logs" do
      expect(step.progress_logs).to(include(log))
    end
  end

  describe "discard" do
    it "is discardable" do
      expect(step).not_to(be_discarded)
      step.discard
      expect(step).to(be_discarded)
      expect(described_class.kept).not_to(include(step))
    end

    it "discards associated progress_logs when discarded" do
      log
      step.discard
      expect(log.reload).to(be_discarded)
    end
  end
end
