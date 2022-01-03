FactoryBot.define do
  factory :equipment do
    born_at { DateTime.new(2017, 6, 1)}
    initial_born_at {}
    sequence(:number) { |n| "E0000#{n}"}
    name { 'Equipment' }
    type { 'Equipment' }
    association :category, factory: :product_nature_category
    association :variant, factory: :equipment_variant
  end

  factory :tractor, class: Equipment do
    initial_born_at {}
    sequence(:number) { |n| "T0000#{n}"}
    name { 'Tractor' }
    type { 'Equipment' }
    born_at { DateTime.new(2017, 6, 1) }
    association :category, factory: :tractor_category
    association :variant, factory: :tractor_variant
  end

  factory :tank, class: Equipment do
    sequence(:number) { |n| "T0000#{n}"}
    name { 'Tank' }
    type { 'Equipment' }
    born_at { DateTime.new(2017, 6, 1) }
  end

  factory :sower, class: Equipment do
    sequence(:number) { |n| "S0000#{n}"}
    name { 'Sower' }
    type { 'Equipment' }
    born_at { DateTime.new(2017, 6, 1) }
    association :category, factory: :sower_category
    association :variant, factory: :sower_variant
  end
end
