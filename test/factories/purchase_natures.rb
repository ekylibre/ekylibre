FactoryBot.define do
  factory :purchase_nature do
    currency { 'EUR' }
    nature { 'purchase' }
    sequence(:name) { |n| "Purchase nature #{n}" }
    with_accounting { true }
    journal
  end
end
