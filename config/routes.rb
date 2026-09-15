Rails.application.routes.draw do
  root "dashboard#show"

  resource  :session, only: %i[ new create destroy ]
  resource  :registration, only: %i[ new create ]
  resources :passwords, param: :token, only: %i[ new create edit update ]
  resources :confirmations, param: :token, only: %i[ new create show ]

  namespace :settings do
    resource :profile, only: %i[ show update ]
    resource :theme, only: :update
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
