# frozen_string_literal: true

module Api
  module V1
    module Auth
      class RefreshController < ApplicationController
        include Api::V1::ErrorHandler

        before_action :validate_refresh_token!

        # POST /api/v1/sessions/refresh
        def create
          @user = @refresh_token.user
          sign_in(@user, store: false)
          render(status: :ok)
        end

        private

        def validate_refresh_token!
          token = params[:refresh_token].presence
          unless token
            render_error("401", "Refresh token is required", :unauthorized)
            return
          end

          @refresh_token = RefreshToken.find_by(token: token)
          unless @refresh_token
            render_error("401", "Invalid refresh token", :unauthorized)
            return
          end

          if @refresh_token.revoked_at.present?
            render_error("401", "Refresh token has been revoked", :unauthorized)
            return
          end

          if @refresh_token.expires_at < Time.current
            render_error("401", "Refresh token has expired", :unauthorized)
            nil
          end
        end
      end
    end
  end
end
