FactoryBot.define do
  factory :tax_declaration do
    financial_year
    sequence(:number) { |n| "TD00#{n}" }
    currency { 'EUR' }
    mode { 'debit' }

    trait :debit do
    end
    trait :payment do
      mode { 'payment' }
    end
  end
end
