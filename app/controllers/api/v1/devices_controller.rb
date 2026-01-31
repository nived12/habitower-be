# frozen_string_literal: true

module Api
  module V1
    class DevicesController < BaseController
      def create
        platform = params[:platform].presence
        token = params[:token].presence

        unless %w[ios android].include?(platform)
          render_error("422", "Platform must be ios or android", :unprocessable_content)
          return
        end
        if token.blank?
          render_error("422", "Token is required", :unprocessable_content)
          return
        end

        device = current_user.devices.find_or_initialize_by(platform: platform)
        device.token = token
        if device.save
          @device = device
          render(:show, status: device.previously_new_record? ? :created : :ok)
        else
          render_validation_errors(device)
        end
      end
    end
  end
end
