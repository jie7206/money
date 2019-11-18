FactoryBot.define do
  factory :deal_record do
    account { "170" }
    deal_type { "buy-limit" }
    data_id { 1113144252 }
    symbol { "btcusdt" }
    amount { 0.03 }
    price { 8800 }
    fees { 0.00001 }
    purpose { "买新电脑" }
    earn_limit { 50 }
    loss_limit { 20 }
    auto_sell { false }
  end
end
