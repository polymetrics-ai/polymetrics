# frozen_string_literal: true

Rails.application.routes.draw do
  mount_devise_token_auth_for "User", at: "auth"

  namespace :api do
    namespace :v1 do
      resources :connectors do
        collection do
          get "definitions"
        end
      end

      resources :connections do
        collection do
          post "start_sync"
          post "stop_sync"
        end
      end

      namespace :agents do
        resources :data_agent, only: [] do
          post :chat, on: :collection
        end
      end
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
