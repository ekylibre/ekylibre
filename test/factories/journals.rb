FactoryBot.define do
  factory :journal do
    closed_on { Date.parse('1997-12-31') }
    sequence(:name) { |i| "Journal #{i}" }
    sequence(:code) { |i| "OP#{i}" }
    currency { 'EUR' }
    nature { 'various' }
    used_for_affairs { true }
    used_for_gaps { true }
    used_for_permanent_stock_inventory { false }
    used_for_tax_declarations { false }
    used_for_unbilled_payables { false }

    trait :various do
    end

    trait :bank do
      nature { 'bank' }
    end

    trait :with_cash do
      after(:create) do |journal|
        create(:cash, journal: journal)
      end
    end
  end
end
