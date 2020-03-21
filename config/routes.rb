Rails.application.routes.draw do

  resources :trial_lists
  root 'deal_records#index'

  resources :properties do
    member do
      get :update_amount, :chart, :delete
    end
  end
  resources :items do
    member do
      get :update_price, :update_amount, :chart, :delete
    end
  end
  resources :portfolios do
    member do
      get :order_up, :order_down, :chart, :delete
    end
  end
  resources :currencies do
    member do
      get :update_exchange_rate_from_to_usd, :chart, :delete
    end
  end
  resources :interests do
    member do
      get :chart, :delete
    end
  end
  resources :records do
    member do
      get :delete
    end
  end
  resources :deal_records do
    member do
      get :delete, :switch_first_sell
    end
  end
  resources :open_orders do
    member do
      get :delete
    end
  end

  get '/login', to: 'main#login'
  get '/logout', to: 'main#logout'
  get '/chart', to: 'main#chart'
  get 'update_huobi_data', to: 'main#update_huobi_data'
  get 'update_all_data', to: 'properties#update_all_data'
  get 'update_all_exchange_rates', to: 'currencies#update_all_exchange_rates'
  get 'update_all_legal_exchange_rates', to: 'currencies#update_all_legal_exchange_rates'
  get 'update_all_digital_exchange_rates', to: 'currencies#update_all_digital_exchange_rates'
  get 'update_btc_exchange_rates', to: 'currencies#update_btc_exchange_rates'
  get 'update_all_portfolios', to: 'portfolios#update_all_portfolios'
  get 'update_house_price', to: 'items#update_house_price'
  get 'clear_deal_records', to: 'deal_records#clear'
  get 'delete_invest_log', to: 'deal_records#delete_invest_log'
  get 'update_deal_records', to: 'deal_records#update_deal_records'
  get 'zip_sell_records', to: 'deal_records#zip_sell_records'
  get 'send_sell_deal_records', to: 'deal_records#send_sell_deal_records'
  get 'send_stop_loss', to: 'deal_records#send_stop_loss'
  get 'sell_to_back', to: 'deal_records#sell_to_back'
  get 'update_huobi_assets', to: 'main#update_huobi_assets'
  get 'update_huobi_records', to: 'main#update_huobi_records'
  get 'place_order_form', to: 'main#place_order_form'
  get 'look_order', to: 'main#look_order'
  post 'place_order', to: 'main#place_order'
  post 'order_calculate', to: 'main#order_calculate'
  get 'invest_log', to: 'main#read_auto_invest_log'
  get 'set_auto_invest_form', to: 'main#set_auto_invest_form'
  post 'set_auto_invest_params', to: 'main#set_auto_invest_params'
  get 'setup_invest_param', to: 'main#setup_invest_param'
  get 'system_params_form', to: 'main#system_params_form'
  post 'update_system_params', to: 'main#update_system_params'
  get 'test_huobi', to: 'main#get_huobi_assets_test'
  get 'check_open_order', to: 'open_orders#check_open_order'
  get 'clear_open_orders', to: 'open_orders#clear'
  get 'huobi_assets', to: 'properties#huobi_assets'
  get 'main/del_huobi_orders'
  get 'main/kline_chart'
  get 'main/line_chart'
  get 'save_trials_to_db', to: 'trial_lists#save_trials_to_db'
end
