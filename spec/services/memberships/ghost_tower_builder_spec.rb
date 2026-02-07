# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Memberships::GhostTowerBuilder) do
  let(:creator) { create(:user) }
  let(:challenge_template) { create(:challenge_template, creator: creator, period_type: "weekly") }
  let(:group) do
    create(:group, challenge_template: challenge_template, creator: creator, start_date: 2.weeks.ago.to_date)
  end
  let(:membership) { create(:membership, group: group, user: create(:user)) }
  let!(:group_step) { create(:group_step, group: group, creator: creator, position: 1) }

  describe "#call" do
    subject(:result) do
      described_class.call(
        membership: membership,
        reference_date: reference_date,
        timezone: timezone,
      )
    end

    let(:reference_date) { Date.current }
    let(:timezone) { "UTC" }

    context "when the member has no log on the reference date" do
      it "returns success" do
        expect(result.success?).to(be(true))
      end

      it "returns ghost tower with status missed" do
        expect(result.payload).to(be_an(Array))
        expect(result.payload.size).to(be <= 3)
        result.payload.each do |item|
          expect(item).to(include(:position, :status))
          expect(item[:status]).to(eq("missed"))
        end
      end
    end

    context "when the member has a log on the reference date" do
      before do
        create(
          :progress_log,
          membership: membership,
          group_step: group_step,
          occurred_at: reference_date.in_time_zone(timezone).noon,
        )
      end

      it "returns success with completed status for that step" do
        expect(result.success?).to(be(true))
        expect(result.payload).to(be_an(Array))
        step_item = result.payload.find { |h| h[:position] == group_step.position }
        expect(step_item).to(be_present)
        expect(step_item[:status]).to(eq("completed"))
      end
    end
  end
end
