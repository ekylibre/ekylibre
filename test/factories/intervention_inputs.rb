FactoryBot.define do
  factory :intervention_input do
    quantity_population { 10 }
    quantity_value { 10 }
    quantity_handler { :population }
    reference_name { 'seeds' }
    product
    intervention

    factory :phyto_intervention_input do
      quantity_value { 2 }
      quantity_handler { :mass_area_density }
      reference_name { :plant_medicine }
      association :product, factory: :phytosanitary_product
    end
  end
end
