Rails.application.routes.draw do

  root 'properties#index'

  resources :currencies
  resources :interests

  resources :properties do
    member do
      get :update_amount
    end
  end
  resources :items do
    member do
      get :update_price, :update_amount
    end
  end
  resources :portfolios do
    member do
      get :order_up, :order_down
    end
  end

  get '/login', to: 'main#login'
  get '/logout', to: 'main#logout'
  get '/test', to: 'main#index'
  get 'update_all_exchange_rates', to: 'currencies#update_all_exchange_rates'
  get 'update_all_portfolios', to: 'portfolios#update_all_portfolios'

end
