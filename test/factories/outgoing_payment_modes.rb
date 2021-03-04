FactoryBot.define do
  factory :outgoing_payment_mode do
    sequence(:name) { |n| "Bank Transfer #{n}" }
    cash
    with_accounting { true }
  end
end
