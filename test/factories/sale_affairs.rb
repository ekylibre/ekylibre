FactoryBot.define do
  factory :sale_affair do
    association :client, factory: %i[entity client]
    sequence(:number) { |n| "AS0#{n}" }
    credit { 0.0 }
    debit { 5000.0 }
    currency { 'EUR' }
  end
end
