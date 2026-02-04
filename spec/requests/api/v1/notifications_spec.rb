# frozen_string_literal: true

require "rails_helper"

RSpec.describe("GET /api/v1/notifications", type: :request) do
  let(:user) { create(:user) }

  subject(:do_request) { get "/api/v1/notifications", headers: auth_headers(user) }

  before { do_request }

  it "returns 200 OK" do
    expect(response).to(have_http_status(:ok))
  end

  it "returns notifications array and meta" do
    expect(parsed_body["notifications"]).to(be_an(Array))
    expect(parsed_body["meta"]).to(have_key("page"))
    expect(parsed_body["meta"]).to(have_key("per_page"))
    expect(parsed_body["meta"]).to(have_key("total"))
  end
end

RSpec.describe("POST /api/v1/notifications/:id/read", type: :request) do
  let(:user) { create(:user) }
  let(:notification) { create(:notification, recipient: user, actor: create(:user), action: "high_five") }

  subject(:do_request) do
    post "/api/v1/notifications/#{notification.id}/read", headers: auth_headers(user)
  end

  before { do_request }

  it "returns 200 OK" do
    expect(response).to(have_http_status(:ok))
  end

  it "marks the notification as read" do
    expect(notification.reload.read_at).to(be_present)
  end
end

RSpec.describe("POST /api/v1/notifications/read_all", type: :request) do
  let(:user) { create(:user) }
  let!(:notification) { create(:notification, recipient: user, actor: create(:user), action: "high_five") }

  subject(:do_request) { post "/api/v1/notifications/read_all", headers: auth_headers(user) }

  before { do_request }

  it "returns 200 OK" do
    expect(response).to(have_http_status(:ok))
  end

  it "marks all notifications as read" do
    expect(notification.reload.read_at).to(be_present)
  end
end
