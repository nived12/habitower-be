# frozen_string_literal: true

module Api
  module V1
    module Auth
      class RefreshController < ApplicationController
        include Api::V1::ErrorHandler

        before_action :validate_refresh_token!

        def create
          @user = @refresh_token.user
          sign_in(@user, store: false)
          render "api/v1/auth/sessions/create", status: :ok
        end

        private

        def validate_refresh_token!
          token = params[:refresh_token].presence
          unless token
            render(json: { errors: [{ status: "401", source: { pointer: "/data" }, detail: "Refresh token is required" }] }, status: :unauthorized)
            return
          end

          @refresh_token = RefreshToken.find_by(token: token)
          unless @refresh_token
            render(json: { errors: [{ status: "401", source: { pointer: "/data" }, detail: "Invalid refresh token" }] }, status: :unauthorized)
            return
          end

          if @refresh_token.revoked_at.present?
            render(json: { errors: [{ status: "401", source: { pointer: "/data" }, detail: "Refresh token has been revoked" }] }, status: :unauthorized)
            return
          end

          if @refresh_token.expires_at < Time.current
            render(json: { errors: [{ status: "401", source: { pointer: "/data" }, detail: "Refresh token has expired" }] }, status: :unauthorized)
            return
          end
        end
      end
    end
  end
end
