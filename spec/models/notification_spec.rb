# frozen_string_literal: true

require "rails_helper"

RSpec.describe(Notification, type: :model) do
  describe "validations" do
    let(:notification) { build(:notification, action: "high_five") }

    it "validates presence of action" do
      notification.action = nil
      expect(notification).not_to(be_valid)
      expect(notification.errors[:action]).to(include("can't be blank"))
    end
  end

  describe "associations" do
    let(:recipient) { create(:user) }
    let(:actor) { create(:user) }
    let(:notification) { create(:notification, recipient: recipient, actor: actor) }

    it "belongs to recipient" do
      expect(notification.recipient).to(eq(recipient))
    end

    it "belongs to actor" do
      expect(notification.actor).to(eq(actor))
    end
  end

  describe "scopes" do
    let(:user) { create(:user) }
    let!(:unread_notification) { create(:notification, recipient: user, read_at: nil) }
    let!(:read_notification) { create(:notification, recipient: user, read_at: Time.current) }

    it "unread scope returns only unread" do
      expect(Notification.for_recipient(user).unread).to(include(unread_notification))
      expect(Notification.for_recipient(user).unread).not_to(include(read_notification))
    end
  end
end
