# frozen_string_literal: true

module Api
  module V1
    module Auth
      class SessionsController < Devise::SessionsController
        respond_to :json

        private

        def respond_with(resource, _opts = {})
          @user = resource
          render(:create, status: :ok)
        end

        def respond_to_on_destroy(_resource)
          render(json: { message: I18n.t("devise.sessions.signed_out") }, status: :ok)
        end
      end
    end
  end
end
