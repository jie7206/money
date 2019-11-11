FactoryBot.define do

  factory :record do

    class_name { "MyString" }
    oid { 1 }
    value { 9.99 }

    trait :net do
      class_name { "NetValue" }
      value { 2300000 }
    end

    trait :net_admin do
      class_name { "NetValueAdmin" }
      value { 3100000 }      
    end

  end

end
