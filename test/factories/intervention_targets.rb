FactoryBot.define do
  factory :intervention_target do
    reference_name { 'land_parcel' }
    product
    intervention
  end
end
