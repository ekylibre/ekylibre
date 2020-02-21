FactoryBot.define do
  factory :intervention_target do
    reference_name { 'land_parcel' }
    association :product, factory: :land_parcel
    intervention
  end
end
