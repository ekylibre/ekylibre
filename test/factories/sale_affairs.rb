FactoryBot.define do
  factory :sale_affair do
    transient {
      amount { 5000 }
    }

    association :client, factory: %i[entity client]
    sequence(:number) { |n| "AS0#{n}" }
    credit { amount < 0 ? -amount : 0.0 }
    debit { amount > 0 ? amount : 0.0 }
    currency { 'EUR' }
  end
end
