FactoryGirl.define do
  factory :tax_declaration do
    # needs financial_year
    sequence(:number) { |n| "TD00#{n}" }
    currency 'EUR'
    mode 'debit'

    trait :debit do
    end
    trait :payment do
      mode 'payment'
    end
  end
end
