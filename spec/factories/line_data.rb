FactoryBot.define do
  factory :line_datum do
    symbol { "MyString" }
    period { "MyString" }
    tid { 1 }
    open { "9.99" }
    close { "9.99" }
    high { "9.99" }
    low { "9.99" }
    vol { "9.99" }
    amount { "9.99" }
    count { 1 }
  end
end
