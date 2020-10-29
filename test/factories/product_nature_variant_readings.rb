FactoryBot.define do
  factory :product_nature_variant_reading do

    trait :net_mass do
      indicator_name { :net_mass }
      measure_value_value { 0.5 }
      measure_value_unit { :kilogram }
      indicator_datatype { :measure }

      association :variant, factory: :copless_phytosanitary_variant
    end
  end
end
