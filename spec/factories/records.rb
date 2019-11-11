FactoryBot.define do
  factory :record do
    class_name { "MyString" }
    oid { 1 }
    value { "9.99" }
  end
end
