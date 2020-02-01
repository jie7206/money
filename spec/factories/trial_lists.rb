FactoryBot.define do
  factory :trial_list do
    trial_date { "2020-02-01" }
    begin_price { "9.99" }
    begin_amount { "9.99" }
    month_cost { 1 }
    month_sell { "9.99" }
    begin_balance { 1 }
    begin_balance_twd { 1 }
    month_grow_rate { "9.99" }
    end_price { "9.99" }
    end_balance { 1 }
    end_balance_twd { 1 }
  end
end
