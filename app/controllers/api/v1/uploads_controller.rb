# frozen_string_literal: true

module Api
  module V1
    class UploadsController < BaseController
      def signed_url
        bucket = Rails.application.credentials.dig(:gcs, :bucket) || ENV["GCS_BUCKET"]
        filename = params[:filename].presence
        content_type = params[:content_type].presence

        if bucket.blank?
          render_error("500", "Upload configuration is missing", :internal_server_error)
          return
        end
        if filename.blank?
          render_error("422", "Filename is required", :unprocessable_content)
          return
        end

        object_key = "uploads/#{current_user.id}/#{SecureRandom.hex(8)}/#{File.basename(filename)}"
        result = Storage::SignedUrlGenerator.call(
          bucket_name: bucket,
          object_key: object_key,
          method: :put,
          content_type: content_type,
        )

        if result.failure?
          render_error("422", result.errors.full_messages.first, :unprocessable_content)
          return
        end

        @url = result.payload[:url]
        @object_key = result.payload[:object_key]
        render(:signed_url, status: :ok)
      end
    end
  end
end
