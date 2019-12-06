FactoryBot.define do
  factory :open_order do
    symbol { "MyString" }
    amount { "9.99" }
    price { "9.99" }
    order_type { "MyString" }
  end
end
