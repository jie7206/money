FactoryBot.define do
  factory :deal_record do
    deal_type { "" }
    symbol { "MyString" }
    amount { "9.99" }
    price { "9.99" }
    fees { "9.99" }
    purpose { "MyString" }
    loss_limit { 1 }
    earn_limit { 1 }
    auto_sell { false }
  end
end
