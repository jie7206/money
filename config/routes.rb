Rails.application.routes.draw do

  root 'properties#index'

  resources :records

  resources :properties do
    member do
      get :update_amount, :chart
    end
  end
  resources :items do
    member do
      get :update_price, :update_amount, :chart
    end
  end
  resources :portfolios do
    member do
      get :order_up, :order_down, :chart
    end
  end
  resources :currencies do
    member do
      get :chart
    end
  end
  resources :interests do
    member do
      get :chart
    end
  end
  
  get '/login', to: 'main#login'
  get '/logout', to: 'main#logout'
  get '/chart', to: 'main#chart'
  get 'update_all_exchange_rates', to: 'currencies#update_all_exchange_rates'
  get 'update_all_portfolios', to: 'portfolios#update_all_portfolios'

end
