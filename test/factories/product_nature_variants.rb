FactoryBot.define do
  factory :product_nature_variant do
    unit_name   { 'Millier de grains' }
    variety     { 'cultivable_zone' }

    association :nature, factory: :product_nature
    association :category, factory: :product_nature_category

    factory :land_parcel_nature_variant do
      association :nature, factory: :land_parcel_nature
      variety { 'land_parcel' }
    end
  end

  factory :corn_plant_variant, class: ProductNatureVariant do
    sequence(:name) { |n| "Corn plant variant - TEST#{n.to_s.rjust(8, '0')}" }
    variety         { :zea_mays }
    unit_name       { :hectare }

    association     :nature, factory: :plants_nature
  end
end
