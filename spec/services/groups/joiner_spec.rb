# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Groups::Joiner) do
  let(:creator) { create(:user) }
  let(:user) { create(:user) }
  let(:challenge) { create(:challenge, creator: creator) }

  describe "#call" do
    context "with a public group" do
      let(:group) { create(:group, challenge: challenge, creator: creator) }

      context "when user is not a member" do
        subject(:result) { described_class.new(group: group, user: user).call }

        it "creates a membership" do
          expect { result }.to(change(Membership, :count).by(1))
        end

        it "returns the membership" do
          expect(result).to(be_a(Membership))
          expect(result.user).to(eq(user))
          expect(result.group).to(eq(group))
        end

        it "sets role to member" do
          expect(result.role).to(eq("member"))
        end

        it "sets status to active" do
          expect(result.status).to(eq("active"))
        end
      end

      context "when user is already a member" do
        before { create(:membership, group: group, user: user) }

        it "raises AlreadyMemberError" do
          expect {
            described_class.new(group: group, user: user).call
          }.to(raise_error(Groups::Joiner::AlreadyMemberError, "User is already a member of this group"))
        end
      end

      context "when user has a discarded membership" do
        before do
          membership = create(:membership, group: group, user: user)
          membership.discard!
        end

        it "allows rejoining" do
          result = described_class.new(group: group, user: user).call
          expect(result).to(be_persisted)
        end
      end
    end

    context "with a private group" do
      let(:group) do
        create(:group, challenge: challenge, creator: creator, privacy_type: "private", invite_code: "ABC123")
      end

      context "with valid invite_code" do
        subject(:result) do
          described_class.new(group: group, user: user, invite_code: "ABC123").call
        end

        it "creates a membership" do
          expect { result }.to(change(Membership, :count).by(1))
        end

        it "is case-insensitive for invite_code" do
          result = described_class.new(group: group, user: user, invite_code: "abc123").call
          expect(result).to(be_persisted)
        end
      end

      context "with invalid invite_code" do
        it "raises InvalidInviteCodeError" do
          expect {
            described_class.new(group: group, user: user, invite_code: "WRONG1").call
          }.to(raise_error(Groups::Joiner::InvalidInviteCodeError, "Invalid invite code"))
        end
      end

      context "without invite_code" do
        it "raises InvalidInviteCodeError" do
          expect {
            described_class.new(group: group, user: user).call
          }.to(raise_error(Groups::Joiner::InvalidInviteCodeError, "Invalid invite code"))
        end
      end

      context "with empty invite_code" do
        it "raises InvalidInviteCodeError" do
          expect {
            described_class.new(group: group, user: user, invite_code: "").call
          }.to(raise_error(Groups::Joiner::InvalidInviteCodeError, "Invalid invite code"))
        end
      end
    end
  end
end
