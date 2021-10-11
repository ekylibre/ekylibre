FactoryBot.define do
  factory :product_nature_variant_reading do
    trait :net_mass do
      indicator_name { :net_mass }
      measure_value_value { 1 }
      measure_value_unit { :kilogram }
      indicator_datatype { :measure }

      association :variant, factory: :plant_medicine_variant
    end

    trait :net_volume do
      indicator_name { :net_volume }
      measure_value_value { 2 }
      measure_value_unit { :liter }
      indicator_datatype { :measure }

      association :variant, factory: :plant_medicine_variant
    end

    trait :thousand_grains_mass do
      indicator_name { :thousand_grains_mass }
      measure_value_value { 300 }
      measure_value_unit { :gram }
      indicator_datatype { :measure }

      association :variant, factory: :seed_variant
    end
  end
end
