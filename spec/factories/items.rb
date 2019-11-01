FactoryBot.define do

  factory :item do

    association :property, :house
    price { 12000.0 }
    amount { 49.47 }
    url { "https://qinhuangdao.anjuke.com/community/trends/387687" }
    
  end

end
