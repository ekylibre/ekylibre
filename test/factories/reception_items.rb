FactoryBot.define do
  factory :reception_item do
    reception
    association :variant, factory: :product_nature_variant
    sequence(:product_name) { |n| "product name #{n}" }
  end
end
