# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Memberships::IntegrityScoreCalculator) do
  let(:creator) { create(:user) }
  let(:challenge_template) { create(:challenge_template, creator: creator, period_type: "weekly") }
  let(:group) do
    create(:group, challenge_template: challenge_template, creator: creator, start_date: 2.weeks.ago.to_date)
  end
  let(:membership) { create(:membership, group: group, user: create(:user)) }
  let!(:group_step) do
    create(:group_step, group: group, creator: creator, position: 1, requirements: { "frequency" => "daily" })
  end

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

    context "when there are no progress logs in the lookback window" do
      it "returns success" do
        expect(result.success?).to(be(true))
      end

      it "returns a score less than 100" do
        expect(result.payload).to(be_a(Numeric))
        expect(result.payload).to(be < 100)
        expect(result.payload).to(be >= 0)
      end
    end

    context "when the member has full logs for the lookback window" do
      before do
        (0..13).each do |days_ago|
          create(
            :progress_log,
            membership: membership,
            group_step: group_step,
            occurred_at: (reference_date - days_ago.days).in_time_zone(timezone).noon,
          )
        end
      end

      it "returns success with score 100" do
        expect(result.success?).to(be(true))
        expect(result.payload).to(eq(100.0))
      end
    end

    context "with a custom reference_date and timezone" do
      let(:reference_date) { 1.week.ago.to_date }
      let(:timezone) { "America/New_York" }

      it "returns success with a numeric score" do
        expect(result.success?).to(be(true))
        expect(result.payload).to(be_a(Numeric))
      end
    end
  end
end
