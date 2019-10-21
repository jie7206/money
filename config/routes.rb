Rails.application.routes.draw do

  resources :properties
  root 'properties#index'
  get '/login', to: 'main#login'
  get '/logout', to: 'main#logout'

end
