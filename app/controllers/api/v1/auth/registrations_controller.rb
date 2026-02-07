# frozen_string_literal: true

module Api
  module V1
    module Auth
      class RegistrationsController < Devise::RegistrationsController
        prepend_before_action :configure_devise_mapping!

        respond_to :json

        private

        def configure_devise_mapping!
          request.env["devise.mapping"] = Devise.mappings[:user]
        end

        def sign_up_params
          params.require(:user).permit(
            :email, :password, :password_confirmation,
            :first_name, :last_name, :avatar_url
          )
        end

        # POST /api/v1/users
        def respond_with(resource, _opts = {})
          if resource.persisted?
            @user = resource
            render(:create, status: :created)
          else
            render(json: { errors: resource.errors.full_messages }, status: :unprocessable_content)
          end
        end
      end
    end
  end
end
