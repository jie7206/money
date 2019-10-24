FactoryBot.define do

  factory :currency do

    name { '日元' }
    code { 'JPY' }
    exchange_rate { 108.00 }

    trait :twd do
      name { '新台币' }
      code { 'TWD' }
      exchange_rate { 32.00 }
    end

    trait :cny do
      name { '人民币' }
      code { 'CNY' }
      exchange_rate { 7.0 }
    end

    trait :usd do
      name { '美元' }
      code { 'USD' }
      exchange_rate { 1.0 }
    end

    trait :krw do
      name { '韩元' }
      code { 'KRW' }
      exchange_rate { 1173.0 }
    end

  end

end
