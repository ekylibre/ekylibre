FactoryGirl.define do
  factory :product_nature_variant do
    unit_name "Millier de grains"
    association :category, factory: :product_nature_category
    association :nature, factory: :product_nature
    variety "cultivable_zone"
  end
end
