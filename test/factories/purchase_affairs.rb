FactoryBot.define do
  factory :purchase_affair do
    association :supplier, factory: %i[entity supplier]
    sequence(:number) { |n| "AP0#{n}" }
    credit { 1848.0 }
    debit { 0.0 }
    currency { 'EUR' }
  end
end
