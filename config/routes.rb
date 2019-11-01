Rails.application.routes.draw do

  resources :items
  resources :interests
  resources :currencies
  resources :properties do
    member do
      get :update_amount
    end
  end
  root 'properties#index'
  get '/login', to: 'main#login'
  get '/logout', to: 'main#logout'
  get 'update_all_exchange_rates', to: 'currencies#update_all_exchange_rates'

end
