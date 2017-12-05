FactoryGirl.define do
  factory :reception_item do
    reception
    association :variant, factory: :product_nature_variant
  end
end
