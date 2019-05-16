FactoryBot.define do
  factory :purchase_order do
    association :supplier, factory: %i[entity supplier]
    association :nature, factory: :purchase_nature
    currency { 'EUR' }
  end
end
