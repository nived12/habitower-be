# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Groups::Creator) do
  let(:user) { create(:user) }
  let(:challenge) { create(:challenge, creator: user) }

  describe "#call" do
    context "with a weekly challenge" do
      let(:challenge) { create(:challenge, creator: user, period_type: "weekly") }

      context "when no start_date is provided" do
        subject(:result) do
          described_class.new(challenge: challenge, creator: user).call
        end

        it "creates a group" do
          expect { result }.to(change(Group, :count).by(1))
        end

        it "sets the challenge" do
          expect(result.challenge).to(eq(challenge))
        end

        it "sets the creator" do
          expect(result.creator).to(eq(user))
        end

        it "defaults to public privacy_type" do
          expect(result.privacy_type).to(eq("public"))
        end

        it "does not set an invite_code for public groups" do
          expect(result.invite_code).to(be_nil)
        end

        it "sets start_date to the next Monday" do
          expect(result.start_date.wday).to(eq(1)) # Monday
          expect(result.start_date).to(be >= Date.current)
        end

        it "creates an admin membership for the creator" do
          group = result
          membership = group.memberships.find_by(user: user)

          expect(membership).to(be_present)
          expect(membership.role).to(eq("admin"))
        end
      end

      context "when today is Monday" do
        before do
          allow(Date).to(receive(:current).and_return(Date.new(2026, 2, 2))) # Monday
        end

        it "sets start_date to today" do
          result = described_class.new(challenge: challenge, creator: user).call
          expect(result.start_date).to(eq(Date.new(2026, 2, 2)))
        end
      end

      context "when today is Wednesday" do
        before do
          allow(Date).to(receive(:current).and_return(Date.new(2026, 2, 4))) # Wednesday
        end

        it "sets start_date to next Monday" do
          result = described_class.new(challenge: challenge, creator: user).call
          expect(result.start_date).to(eq(Date.new(2026, 2, 9)))
        end
      end
    end

    context "with a monthly challenge" do
      let(:challenge) { create(:challenge, creator: user, period_type: "monthly") }

      context "when today is the 1st" do
        before do
          allow(Date).to(receive(:current).and_return(Date.new(2026, 2, 1)))
        end

        it "sets start_date to today" do
          result = described_class.new(challenge: challenge, creator: user).call
          expect(result.start_date).to(eq(Date.new(2026, 2, 1)))
        end
      end

      context "when today is not the 1st" do
        before do
          allow(Date).to(receive(:current).and_return(Date.new(2026, 2, 15)))
        end

        it "sets start_date to the 1st of next month" do
          result = described_class.new(challenge: challenge, creator: user).call
          expect(result.start_date).to(eq(Date.new(2026, 3, 1)))
        end
      end
    end

    context "with explicit start_date" do
      let(:custom_date) { Date.new(2026, 6, 1) }

      it "uses the provided start_date" do
        result = described_class.new(
          challenge: challenge,
          creator: user,
          start_date: custom_date,
        ).call

        expect(result.start_date).to(eq(custom_date))
      end
    end

    context "with private privacy_type" do
      subject(:result) do
        described_class.new(
          challenge: challenge,
          creator: user,
          privacy_type: "private",
        ).call
      end

      it "creates a private group" do
        expect(result.privacy_type).to(eq("private"))
      end

      it "generates a 6-character invite_code" do
        expect(result.invite_code).to(be_present)
        expect(result.invite_code.length).to(eq(6))
      end

      it "generates an uppercase alphanumeric invite_code" do
        expect(result.invite_code).to(match(/\A[A-Z0-9]+\z/))
      end

      it "generates unique invite_codes" do
        codes = 10.times.map do
          described_class.new(
            challenge: challenge,
            creator: user,
            privacy_type: "private",
          ).call.invite_code
        end

        expect(codes.uniq.size).to(eq(10))
      end
    end

    context "transaction rollback" do
      before do
        allow_any_instance_of(Membership).to(receive(:save!).and_raise(ActiveRecord::RecordInvalid))
      end

      it "rolls back group creation if membership fails" do
        expect {
          described_class.new(challenge: challenge, creator: user).call rescue nil
        }.not_to(change(Group, :count))
      end
    end
  end
end
