FactoryBot.define do
  factory :journal do
    # closed_on { Date.parse('1997-12-31') }
    sequence(:name) { |i| "Journal #{i}" }
    # WARN: Will fail uniqueness constraint if more than 1000 journals are created
    # "[J100]0 [J100]1" => J100 x2 bc 4-chars codes
    sequence(:code) { |i| "J#{i.to_s.ljust(2, '0')}" }
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
