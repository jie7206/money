Rails.application.routes.draw do

  resources :properties
  root 'main#index'
  get '/login', to: 'main#login'
  get '/logout', to: 'main#logout'

end
