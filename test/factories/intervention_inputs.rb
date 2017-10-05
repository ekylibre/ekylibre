FactoryGirl.define do
  factory :intervention_input do
    reference_name 'plant_medicine'
    association :product, factory: :preparation
    association :intervention, factory: :spraying
  end
end
