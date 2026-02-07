# frozen_string_literal: true

require "swagger_helper"

RSpec.describe("Uploads API", type: :request) do
  let(:user) { create(:user) }
  let(:Authorization) { "Bearer #{Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first}" }

  path "/api/v1/uploads" do
    post "Create upload (get signed URL)" do
      tags "Uploads"
      security [bearer_auth: []]
      produces "application/json"
      consumes "application/json"
      parameter name: :Authorization, in: :header, type: :string, required: true, description: "Bearer JWT"
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          filename: { type: :string, example: "photo.jpg" },
          content_type: { type: :string, example: "image/jpeg" }
        },
        required: ["filename"]
      }

      response "200", "success" do
        let(:body) { { filename: "photo.jpg", content_type: "image/jpeg" } }

        before do
          allow(Rails.application.credentials).to(receive(:dig).with(:gcs, :bucket).and_return("test-bucket"))
          allow(Storage::SignedUrlGenerator).to(
            receive(:call).and_return(
              ApplicationService::Response.new(
                success: true,
                payload: { url: "https://storage.example.com/signed", object_key: "uploads/1/abc/photo.jpg" },
                errors: nil
              )
            )
          )
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to(have_key("url"))
          expect(data).to(have_key("object_key"))
        end
      end

      response "422", "filename required" do
        let(:body) { { filename: "" } }

        before do
          allow(Rails.application.credentials).to(receive(:dig).with(:gcs, :bucket).and_return("test-bucket"))
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to(have_key("errors"))
        end
      end

      response "401", "unauthorized" do
        let(:body) { { filename: "photo.jpg" } }
        let(:Authorization) { nil }
        run_test!
      end
    end
  end
end
