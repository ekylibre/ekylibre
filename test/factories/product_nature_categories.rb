FactoryBot.define do
  factory :product_nature_category do
    sequence(:name) { |n| "Category #{n}" }
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
end
