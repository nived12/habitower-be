# frozen_string_literal: true

require "swagger_helper"

RSpec.describe("Notifications API", type: :request) do
  let(:user) { create(:user) }
  let(:Authorization) { "Bearer #{Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first}" }

  path "/api/v1/notifications" do
    get "List notifications" do
      tags "Notifications"
      security [bearer_auth: []]
      produces "application/json"
      parameter name: :Authorization, in: :header, type: :string, required: true, description: "Bearer JWT"
      parameter name: :page, in: :query, type: :integer, required: false
      parameter name: :per_page, in: :query, type: :integer, required: false

      response "200", "success" do
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to(have_key("notifications"))
          expect(data).to(have_key("meta"))
        end
      end

      response "401", "unauthorized" do
        let(:Authorization) { nil }
        run_test!
      end
    end
  end

  path "/api/v1/notifications/{id}/read" do
    parameter name: :id, in: :path, type: :integer, required: true, description: "Notification ID"
    let(:notification) { create(:notification, recipient: user, actor: create(:user), action: "high_five") }
    let(:id) { notification.id }

    post "Mark notification as read" do
      tags "Notifications"
      security [bearer_auth: []]
      produces "application/json"
      parameter name: :Authorization, in: :header, type: :string, required: true, description: "Bearer JWT"

      response "200", "success" do
        run_test!
      end
    end
  end

  path "/api/v1/notifications/read_all" do
    post "Mark all notifications as read" do
      tags "Notifications"
      security [bearer_auth: []]
      parameter name: :Authorization, in: :header, type: :string, required: true, description: "Bearer JWT"

      response "200", "success" do
        run_test!
      end
    end
  end
end
