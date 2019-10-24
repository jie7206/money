FactoryBot.define do

  factory :currency do
    name { '新台币' }
    code { 'TWD' }
    exchange_rate { 31.5 }

    trait :cny do
      name { '人民币' }
      code { 'CNY' }
      exchange_rate { 7.0 }
    end

  end

end
