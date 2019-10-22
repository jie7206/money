FactoryBot.define do

  factory :currency do
    name { '新台币' }
    code { 'TWD' }
    exchange_rate { 31.5 }
  end

end
