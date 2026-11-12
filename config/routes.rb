Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  resource :registration, only: %i[ new create ]

  resources :decisions, only: %i[ index show ] do
    resources :passages, only: :show
    resources :comments, only: %i[ index create destroy ]
    resource :import, only: :create, module: :decisions
  end

  namespace :admin do
    resources :terms, only: [] do
      resource :sync, only: :create
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check

  root "decisions#index"
end
