FactoryGirl.define do
  factory :intervention_tool do
    reference_name 'tractor'
    association :product, factory: :equipment
    association :intervention, factory: :spraying
  end
end
