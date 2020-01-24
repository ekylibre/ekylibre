FactoryBot.define do
  factory :product_nature_category do
    sequence(:name) { |n| "Category #{n}" }
    association :product_account, factory: :account
    factory :deliverable_category do
      storable { true }
      purchasable { true }
      charge_account
      stock_account
      stock_movement_account
    end
  end

  factory :plants_category, class: ProductNatureCategory do
    sequence(:name) { |n| "Crops - TEST#{n.to_s.rjust(8, '0')}" }
  end

  factory :equipment_category, class: ProductNatureCategory do
    sequence(:name) { |n| "Equipments category - TEST#{n.to_s.rjust(8, '0')}" }
    depreciable { true }
    asset_fixable { true }
    fixed_asset_depreciation_method { :linear }
    association :product_account, factory: :account
    fixed_asset_account
    fixed_asset_allocation_account
    fixed_asset_expenses_account
  end

  factory :building_division_category, class: ProductNatureCategory do
    sequence(:name) { |n| "Building divison category - #{n}" }
  end

  factory :fertilizer_category, class: ProductNatureCategory do
    sequence(:name) { |n| "Fertilizers - TEST#{n.to_s.rjust(8, '0')}" }
    reference_name { "fertilizer" }
  end

  factory :tractor_category, class: ProductNatureCategory do
    sequence(:name) { |n| "Tractors - TEST#{n.to_s.rjust(8, '0')}" }
    reference_name { "equipment" }
  end

  factory :seed_category, class: ProductNatureCategory do
    sequence(:name) { |n| "Seeds - TEST#{n.to_s.rjust(8, '0')}" }
    reference_name { "seed" }
  end

  factory :harvest_category, class: ProductNatureCategory do
    sequence(:name) { |n| "Harvests - TEST#{n.to_s.rjust(8, '0')}" }
  end
end
