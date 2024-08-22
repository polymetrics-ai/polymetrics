# frozen_string_literal: true

Rails.application.routes.draw do
  mount_devise_token_auth_for "User", at: "auth"

  namespace :api do
    namespace :v1 do
      resources :connectors
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
