FactoryBot.define do
  factory :intervention_input do
    quantity_population { 10 }
    quantity_value { 10 }
    quantity_handler { :population }
    reference_name { 'seeds' }
    product
    intervention
  end
end
