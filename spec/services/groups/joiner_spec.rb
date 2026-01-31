# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Groups::Joiner) do
  let(:creator) { create(:user) }
  let(:user) { create(:user) }
  let(:challenge_template) { create(:challenge_template, creator: creator) }

  describe "#call" do
    context "with a public group" do
      let(:group) { create(:group, challenge_template: challenge_template, creator: creator) }

      context "when user is not a member" do
        subject(:result) { described_class.call(group: group, user: user) }

        it "creates a membership" do
          expect { result }.to(change(Membership, :count).by(1))
        end

        it "returns success with membership payload" do
          expect(result.success?).to(be(true))
          expect(result.payload).to(be_a(Membership))
          expect(result.payload.user).to(eq(user))
          expect(result.payload.group).to(eq(group))
        end

        it "sets role to member" do
          expect(result.payload.role).to(eq("member"))
        end

        it "sets status to active" do
          expect(result.payload.status).to(eq("active"))
        end
      end

      context "when user is already a member" do
        before { create(:membership, group: group, user: user) }

        it "returns failure with message" do
          result = described_class.call(group: group, user: user)

          expect(result.failure?).to(be(true))
          expect(result.errors.full_messages.first).to(include("already a member"))
        end
      end

      context "when user has a discarded membership" do
        before do
          membership = create(:membership, group: group, user: user)
          membership.discard!
        end

        it "allows rejoining" do
          result = described_class.call(group: group, user: user)
          expect(result.success?).to(be(true))
          expect(result.payload).to(be_persisted)
        end
      end
    end

    context "with a private group" do
      let(:group) do
        create(:group, challenge_template: challenge_template, creator: creator, privacy_type: "private", invite_code: "ABC123")
      end

      context "with valid invite_code" do
        subject(:result) do
          described_class.call(group: group, user: user, invite_code: "ABC123")
        end

        it "creates a membership" do
          expect { result }.to(change(Membership, :count).by(1))
        end

        it "is case-insensitive for invite_code" do
          result = described_class.call(group: group, user: user, invite_code: "abc123")
          expect(result.success?).to(be(true))
          expect(result.payload).to(be_persisted)
        end
      end

      context "with invalid invite_code" do
        it "returns failure" do
          result = described_class.call(group: group, user: user, invite_code: "WRONG1")

          expect(result.failure?).to(be(true))
          expect(result.errors.full_messages.first).to(include("Invalid invite code"))
        end
      end

      context "without invite_code" do
        it "returns failure" do
          result = described_class.call(group: group, user: user)

          expect(result.failure?).to(be(true))
          expect(result.errors.full_messages.first).to(include("Invalid invite code"))
        end
      end

      context "with empty invite_code" do
        it "returns failure" do
          result = described_class.call(group: group, user: user, invite_code: "")

          expect(result.failure?).to(be(true))
          expect(result.errors.full_messages.first).to(include("Invalid invite code"))
        end
      end
    end
  end
end
