# frozen_string_literal: true

Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"

  get "up" => "rails/health#show", as: :rails_health_check

  scope :api, defaults: { format: :json } do
    scope :v1 do
      devise_for :users,
        skip: [:registrations],
        path: "",
        path_names: { sign_in: "auth/login", sign_out: "auth/logout" },
        controllers: { sessions: "api/v1/auth/sessions" }

      devise_scope :user do
        post "auth/sign_up", to: "api/v1/auth/registrations#create", as: :user_registration
      end
    end
  end
end
