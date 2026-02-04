# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Reaction, type: :model) do
  describe "validations" do
    let(:user) { create(:user) }
    let(:group) { create(:group) }
    let(:membership) { create(:membership, group: group) }
    let(:group_step) { create(:group_step, group: group) }
    let(:progress_log) { create(:progress_log, membership: membership, group_step: group_step) }

    it "validates uniqueness of user_id scoped to progress_log_id and kind" do
      create(:reaction, user: user, progress_log: progress_log, kind: "high_five")
      duplicate = build(:reaction, user: user, progress_log: progress_log, kind: "high_five")
      expect(duplicate).not_to(be_valid)
      expect(duplicate.errors[:user_id]).to(be_present)
    end

    it "allows same user to have high_five and nudge on same progress_log" do
      create(:reaction, user: user, progress_log: progress_log, kind: "high_five")
      nudge = build(:reaction, user: user, progress_log: progress_log, kind: "nudge")
      expect(nudge).to(be_valid)
    end
  end

  describe "associations" do
    let(:reaction) { create(:reaction) }

    it "belongs to user" do
      expect(reaction.user).to(be_present)
    end

    it "belongs to progress_log" do
      expect(reaction.progress_log).to(be_present)
    end
  end

  describe "enum kind" do
    it "has high_five and nudge" do
      expect(Reaction.kinds).to(include("high_five" => "high_five", "nudge" => "nudge"))
    end
  end
end
