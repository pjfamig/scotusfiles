Rails.application.routes.draw do
  root "opinions#index"
  resources :opinions do
    member do
      delete :delete_file
    end
  end  
end
