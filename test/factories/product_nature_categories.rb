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

  factory :equipments_category, class: ProductNatureCategory do
    sequence(:name) { |n| "Equipments category - TEST#{n.to_s.rjust(8, '0')}" }
    depreciable { true }
    asset_fixable { true }
    fixed_asset_depreciation_method { :linear }
    association :product_account, factory: :account
    fixed_asset_account
    fixed_asset_allocation_account
    fixed_asset_expenses_account
  end
end
