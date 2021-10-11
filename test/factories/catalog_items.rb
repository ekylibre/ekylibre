FactoryBot.define do
  factory :catalog_item do
    catalog
    association :variant, factory: :equipment_variant
    sequence(:name) { |n| "Catalog item #{n}"}
    started_at { Date.new(2020, 1, 1) }
    amount { 5000 }
  end
end
