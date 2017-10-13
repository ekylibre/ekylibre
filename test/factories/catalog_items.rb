FactoryGirl.define do
  factory :catalog_item do
    catalog
    amount 50.0.to_d
    association :variant, factory: :equipment
    sequence(:name) { |n| "Catalog Item #{n}" }
  end
end
