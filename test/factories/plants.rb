FactoryGirl.define do
  factory :corn_plant, class: Plant do
    sequence(:name) { |n| "Corn plant - TEST#{n.to_s.rjust(8, '0')}" }
    variety         :zea_mays

    association     :variant, factory: :corn_plant_variant
  end
end
