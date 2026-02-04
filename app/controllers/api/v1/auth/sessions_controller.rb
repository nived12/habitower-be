# frozen_string_literal: true

module Api
  module V1
    module Auth
      class SessionsController < Devise::SessionsController
        respond_to :json

        private

        def respond_with(resource, _opts = {})
          @user = resource
          @refresh_token = create_refresh_token_for(resource)
          render(:create)
        end

        def respond_to_on_destroy(_resource)
          revoke_refresh_token_if_present
          render(json: { message: I18n.t("devise.sessions.signed_out") }, status: :ok)
        end

        def create_refresh_token_for(user)
          user.refresh_tokens.create!(
            token: SecureRandom.urlsafe_base64(32),
            expires_at: 30.days.from_now,
          )
        end

        def revoke_refresh_token_if_present
          token = params[:refresh_token].presence
          return unless token

          RefreshToken.find_by(token: token)&.update!(revoked_at: Time.current)
        end
      end
    end
  end
end
