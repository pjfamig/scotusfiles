Rails.application.routes.draw do
  devise_for :users
  root "opinions#index"
  resources :opinions do
    resources :comments, only: [:create]
    member do
      delete :delete_file
    end
  end  
end
