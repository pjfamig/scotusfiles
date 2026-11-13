Rails.application.routes.draw do
  # Send the bare domain and the Heroku app domain to the canonical host so search engines index one copy of each page.
  constraints CanonicalHostConstraint do
    match "(*path)", via: %i[get head], format: false,
      to: redirect { |_params, request| "https://#{Rails.configuration.x.canonical_host}#{request.fullpath}" }
  end

  resource :session
  resources :passwords, param: :token
  resource :registration, only: %i[ new create ]
  resource :highlight_color, only: :update

  resources :decisions, only: %i[ index show ] do
    resources :passages, only: :show
    resources :comments, only: %i[ index create destroy ]
    resource :import, only: :create, module: :decisions
  end
  get "terms/:term", to: "decisions#index", as: :term, constraints: { term: /\d{4}/ }
  get "feed", to: "decisions#feed", as: :feed, defaults: { format: :atom }

  get "sitemap.xml", to: "seo#sitemap", as: :sitemap, defaults: { format: :xml }
  get "robots.txt", to: "seo#robots", as: :robots, defaults: { format: :text }
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  namespace :admin do
    root "dashboards#show"
    resources :users, only: :index
    resources :comments, only: :index
    resources :imports, only: :index
    resources :terms, only: [] do
      resource :sync, only: :create
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check

  root "decisions#index"
end
