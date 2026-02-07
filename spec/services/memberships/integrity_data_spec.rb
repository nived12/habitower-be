# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Memberships::IntegrityData) do
  let(:creator) { create(:user) }
  let(:challenge_template) { create(:challenge_template, creator: creator, period_type: "weekly") }
  let(:group) do
    create(:group, challenge_template: challenge_template, creator: creator, start_date: 2.weeks.ago.to_date)
  end
  let(:membership) { create(:membership, group: group, user: create(:user)) }
  let(:membership_b) { create(:membership, group: group, user: create(:user)) }
  let(:memberships) { [membership, membership_b] }

  describe ".for_batch" do
    subject(:result) do
      described_class.for_batch(
        memberships,
        timezone: "UTC",
        reference_date: Date.current
      )
    end

    it "returns a hash keyed by membership id" do
      expect(result).to(be_a(Hash))
      expect(result.keys).to(match_array(memberships.map(&:id)))
    end

    it "includes score and ghost_tower for each membership" do
      result.each_value do |payload|
        expect(payload).to(include(:score, :ghost_tower))
        expect(payload[:score]).to(be_a(Numeric))
        expect(payload[:ghost_tower]).to(be_an(Array))
      end
    end
  end
end
