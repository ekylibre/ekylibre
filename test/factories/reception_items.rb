FactoryBot.define do
  factory :reception_item do
    reception
    association :variant, factory: :deliverable_variant
    sequence(:product_name) { |n| "product name #{n}" }
  end
end
