FactoryBot.define do

  factory :portfolio do

    name { "冷钱包的比特币" }
    include_tags { "比特币 冷钱包" }
    exclude_tags { "家庭资产" }
    order_num { 1 }
    mode { 'n' }

  end

end
