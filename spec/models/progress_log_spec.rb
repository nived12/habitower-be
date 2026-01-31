# frozen_string_literal: true

require "rails_helper"

RSpec.describe(ProgressLog, type: :model) do
  let(:creator) { create(:user) }
  let(:user) { create(:user) }
  let(:challenge_template) { create(:challenge_template, creator: creator) }
  let(:group) { create(:group, challenge_template: challenge_template, creator: creator) }
  let(:membership) { create(:membership, user: user, group: group) }
  let(:group_step) { create(:group_step, group: group, creator: creator) }
  let(:log) do
    create(:progress_log, membership: membership, group_step: group_step)
  end

  describe "validations" do
    it "validates presence of membership" do
      invalid = build(:progress_log, membership: nil, group_step: group_step)
      expect(invalid).not_to(be_valid)
      expect(invalid.errors[:membership]).to(include("must exist"))
    end

    it "validates presence of group_step" do
      invalid = build(:progress_log, membership: membership, group_step: nil)
      expect(invalid).not_to(be_valid)
      expect(invalid.errors[:group_step]).to(include("must exist"))
    end

    it "validates presence of value" do
      invalid = build(:progress_log, membership: membership, group_step: group_step, value: nil)
      expect(invalid).not_to(be_valid)
      expect(invalid.errors[:value]).to(include("can't be blank"))
    end

    it "validates presence of occurred_at" do
      invalid = build(:progress_log, membership: membership, group_step: group_step, occurred_at: nil)
      expect(invalid).not_to(be_valid)
      expect(invalid.errors[:occurred_at]).to(include("can't be blank"))
    end
  end

  describe "associations" do
    it "belongs to membership" do
      expect(log.membership).to(eq(membership))
    end

    it "belongs to group_step" do
      expect(log.group_step).to(eq(group_step))
    end
  end

  describe "discard" do
    it "is discardable" do
      expect(log).not_to(be_discarded)
      log.discard
      expect(log).to(be_discarded)
      expect(described_class.kept).not_to(include(log))
    end
  end
end
