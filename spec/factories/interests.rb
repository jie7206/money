FactoryBot.define do

  factory :interest do

    association :property, :twd_loan
    start_date { "2019-10-01".to_date }
    rate { 4.50 }

  end

end
