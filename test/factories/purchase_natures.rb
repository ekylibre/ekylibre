FactoryBot.define do
  factory :purchase_nature do
    currency { 'EUR' }
    nature { 'purchase' }
    sequence(:name) { |i| "name #{i}" }
    with_accounting { true }
    journal
  end
end
