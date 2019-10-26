FactoryBot.define do

  factory :property do

    name { '现金' }
    amount { 10000.0 }
    association :currency, :krw

    trait :twd do
      name { '台北银行' }
      amount { 100.0 }
      association :currency, :twd
    end

    trait :twd_loan do
      name { '新光银行' }
      amount { -50.0 }
      association :currency, :twd
    end

    trait :cny do
      name { '我的工商银行账户' }
      amount { 10.0 }
      association :currency, :cny
    end

    trait :usd do
      name { '币托比特币总值' }
      amount { 150.00 }
      association :currency, :usd
    end

  end

end
