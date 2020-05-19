FactoryBot.define do
  factory :equipment do
    sequence(:number) { |n| "E0000#{n}"}
    name { 'Equipment' }
    type { 'Equipment' }
    association :category, factory: :product_nature_category
    association :variant, factory: :equipment_variant
  end

  factory :tractor, class: Equipment do
    sequence(:number) { |n| "T0000#{n}"}
    name { 'Tractor' }
    type { 'Equipment' }
    association :category, factory: :tractor_category
    association :variant, factory: :tractor_variant
  end
end
