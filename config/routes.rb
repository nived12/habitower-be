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
        path_names: { sign_in: "sessions", sign_out: "sessions" },
        controllers: { sessions: "api/v1/auth/sessions" }

      devise_scope :user do
        post "sessions/refresh", to: "api/v1/auth/refresh#create"
      end
    end
  end

  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :users, only: [:create], controller: "auth/registrations"

      resources :challenges, only: [:index, :show, :create, :update, :destroy] do
        resources :challenge_steps, only: [:index, :show, :create, :update, :destroy]
      end

      resources :groups, only: [:index, :show, :create, :update, :destroy] do
        resources :member_towers, only: [:index], path: "member-towers"
        resources :memberships, only: [:index, :create, :destroy] do
          member do
            get :active_stack, path: "active-stack"
            get :integrity
          end
        end
      end

      # Singular resource: one feed per user (Rails convention)
      resource :feed, only: [:show], controller: "feed"

      resources :progress_logs, only: [:create] do
        resources :reactions, only: [:create, :destroy]
      end

      # Singular resource: current user profile + nested follow lists (Rails convention)
      resource :me, only: [:show, :update], controller: "profile", as: "current_user" do
        get :followers, to: "follows#followers"
        get :following, to: "follows#index"
      end

      resources :notifications, only: [:index, :update] do
        collection do
          post :read_all
        end
      end

      resources :follows, only: [:create, :destroy]

      resources :categories, only: [:index]

      resources :uploads, only: [:create], path: "uploads"

      resources :devices, only: [:create]
    end
  end
end
