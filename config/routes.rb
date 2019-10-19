Rails.application.routes.draw do

  root 'main#index'
  get '/login', to: 'main#login'
  get '/logout', to: 'main#logout'

end
