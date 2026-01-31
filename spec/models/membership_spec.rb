# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Membership, type: :model) do
  let(:user) { create(:user) }
  let(:creator) { create(:user) }
  let(:challenge_template) { create(:challenge_template, creator: creator) }
  let(:group) { create(:group, challenge_template: challenge_template, creator: creator) }
  let(:membership) { create(:membership, user: user, group: group) }
  let(:group_step) { create(:group_step, group: group, creator: creator) }
  let(:log) { create(:progress_log, membership: membership, group_step: group_step) }

  describe "validations" do
    it "validates uniqueness of user_id scoped to group_id" do
      create(:membership, user: user, group: group)
      duplicate = build(:membership, user: user, group: group)
      expect(duplicate).not_to(be_valid)
      expect(duplicate.errors[:user_id]).to(be_present)
    end

    it "validates presence of user" do
      invalid = build(:membership, user: nil, group: group)
      expect(invalid).not_to(be_valid)
      expect(invalid.errors[:user]).to(include("must exist"))
    end

    it "validates presence of group" do
      invalid = build(:membership, user: user, group: nil)
      expect(invalid).not_to(be_valid)
      expect(invalid.errors[:group]).to(include("must exist"))
    end
  end

  describe "associations" do
    it "belongs to user" do
      expect(membership.user).to(eq(user))
    end

    it "belongs to group" do
      expect(membership.group).to(eq(group))
    end

    it "has many progress_logs" do
      expect(membership.progress_logs).to(include(log))
    end
  end

  describe "enums" do
    it "defines role with member and admin" do
      expect(membership).to(respond_to(:member?))
      expect(membership).to(respond_to(:admin?))
    end

    it "defines status with active and inactive" do
      expect(membership).to(respond_to(:active?))
      expect(membership).to(respond_to(:inactive?))
    end

    it "defaults role to member" do
      expect(membership.role).to(eq("member"))
      expect(membership.member?).to(be(true))
    end

    it "defaults status to active" do
      expect(membership.status).to(eq("active"))
      expect(membership.active?).to(be(true))
    end
  end

  describe "discard" do
    it "is discardable" do
      expect(membership).not_to(be_discarded)
      membership.discard
      expect(membership).to(be_discarded)
      expect(described_class.kept).not_to(include(membership))
    end

    it "discards associated progress_logs when discarded" do
      log
      membership.discard
      expect(log.reload).to(be_discarded)
    end
  end
end
