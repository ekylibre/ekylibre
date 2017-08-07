FactoryGirl.define do
  factory :product do
    association :category, factory: :product_nature_category
    association :nature, factory: :product_nature
    association :variant, factory: :product_nature_variant
    variety "cultivable_zone"
  end
end
