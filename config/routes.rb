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

  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      post "auth/refresh", to: "auth/refresh#create"

      resources :challenges, only: [:index, :show, :create, :update, :destroy] do
        resources :challenge_steps, only: [:index, :show, :create, :update, :destroy]
      end

      resources :groups, only: [:index, :show, :create, :update, :destroy] do
        member do
          post :join
          delete :leave
        end
        resources :memberships, only: [:index, :create, :destroy]
      end

      get "memberships/:id/active_stack", to: "memberships#active_stack"
      get "memberships/:id/integrity", to: "memberships#integrity"

      get "uploads/signed_url", to: "uploads#signed_url"
      resources :devices, only: [:create]
    end
  end
end
