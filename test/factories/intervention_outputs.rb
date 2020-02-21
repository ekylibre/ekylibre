FactoryBot.define do
  factory :intervention_output do
    quantity_population { 10 }
    reference_name { 'matters' }
    association :variant, factory: :corn_plant_variant
    association :intervention, :harvesting

    factory :plant_output do
      reference_name { 'plant' }
    end
  end
end
