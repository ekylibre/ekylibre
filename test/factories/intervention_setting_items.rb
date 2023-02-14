FactoryBot.define do
  factory :intervention_setting_item do
    trait :of_spray_mix_volume_area_density do
      indicator_name { "spray_mix_volume_area_density" }
      indicator_datatype  { "measure" }
      measure_value_value { 1.0 }
      measure_value_unit { "liter_per_hectare"}
      intervention
    end

    trait :of_engine_speed do
      indicator_name { "engine_speed" }
      indicator_datatype  { "measure" }
      measure_value_value { 1.0 }
      measure_value_unit { "revolution_per_minute"}
      intervention_parameter_setting
    end

    trait :of_ground_speed do
      indicator_name { "ground_speed" }
      indicator_datatype  { "measure" }
      measure_value_value { 1.0 }
      measure_value_unit { "kilometer_per_hour"}
      intervention_parameter_setting
    end
  end
end
