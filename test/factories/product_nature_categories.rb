FactoryBot.define do
  factory :product_nature_category do
    sequence(:name) { |n| "Category #{n}" }
    type { 'VariantCategories::ArticleCategory' }

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
    type { 'VariantCategories::CropCategory' }
  end

  factory :equipment_category, class: ProductNatureCategory do
    sequence(:name) { |n| "Equipments category - TEST#{n.to_s.rjust(8, '0')}" }
    type { 'VariantCategories::EquipmentCategory' }
    depreciable { true }
    asset_fixable { true }
    fixed_asset_depreciation_method { :linear }
    fixed_asset_account
    fixed_asset_allocation_account
    fixed_asset_expenses_account

    association :product_account, factory: :account
  end

  factory :building_division_category, class: ProductNatureCategory do
    sequence(:name) { |n| "Building divison category - #{n}" }
    type { 'VariantCategories::ZoneCategory' }
  end

  factory :animal_category, class: ProductNatureCategory do
    sequence(:name) { |n| "Animal category - #{n}" }
    type { 'VariantCategories::AnimalCategory' }
  end

  factory :fertilizer_category, class: ProductNatureCategory do
    sequence(:name) { |n| "Fertilizers - TEST#{n.to_s.rjust(8, '0')}" }
    type { 'VariantCategories::ArticleCategory' }
    reference_name { "fertilizer" }
  end

  factory :phytosanitary_category, class: ProductNatureCategory do
    sequence(:name) { |n| "Plant Medicines - TEST#{n.to_s.rjust(8, '0')}" }
    type { 'VariantCategories::ArticleCategory' }
    reference_name { 'plant_medicine' }
  end

  factory :tractor_category, class: ProductNatureCategory do
    sequence(:name) { |n| "Tractors - TEST#{n.to_s.rjust(8, '0')}" }
    type { 'VariantCategories::EquipmentCategory' }
    reference_name { "equipment" }
  end

  factory :seed_category, class: ProductNatureCategory do
    sequence(:name) { |n| "Seeds - TEST#{n.to_s.rjust(8, '0')}" }
    type { 'VariantCategories::ArticleCategory' }
    reference_name { "seed" }
  end

  factory :harvest_category, class: ProductNatureCategory do
    sequence(:name) { |n| "Harvests - TEST#{n.to_s.rjust(8, '0')}" }
    type { 'VariantCategories::ArticleCategory' }
  end

  factory :land_parcel_category, class: ProductNatureCategory do
    sequence(:name) { |n| "Land parcels - TEST#{n.to_s.rjust(8, '0')}" }
    reference_name { "land_parcel" }
    type { 'VariantCategories::ZoneCategory' }
  end

  factory :plant_medicine_category, class: ProductNatureCategory do
    sequence(:name) { |n| "Plant medicine Category - TEST#{n.to_s.rjust(8, '0')}" }
    type { 'VariantCategories::ArticleCategory' }
    reference_name { "plant_medicine" }
  end
end
