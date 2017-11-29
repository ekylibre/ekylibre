FactoryGirl.define do
  factory :sale do
    association :nature, factory: :sale_nature
    association :affair, factory: :sale_affair
    sequence(:number) { |n| "S00#{n}" }
    amount 5000.0
    downpayment_amount 0.0
    pretax_amount 4180.602
    currency 'EUR'
    payment_delay '12 days, eom, 1 week ago'
    state 'invoice'

    after(:build) do |sale|
      sale.client = sale.affair.client unless sale.client
    end

    factory :sale_with_accounting do
      association :nature, factory: :sale_nature_with_accounting
    end
  end
end
