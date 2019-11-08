FactoryBot.define do

  factory :property do

    name { '现金' }
    amount { 10000.0 }
    is_hidden { false }
    tag_list { '个人资产' }
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

    trait :usd_hidden do
      name { '个人比特币' }
      amount { 10000.0 }
      is_hidden { true }
      association :currency, :usd
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

    trait :house do
      name { '我的房产' }
      amount { 600000.00 }
      association :currency, :cny
    end

    trait :stock do
      name { '台积电' }
      amount { 300000.00 }
      association :currency, :twd
    end

    trait :btc do
      name { '个人比特币' }
      amount { 2.0 }
      association :currency, :btc
    end

  end

end
