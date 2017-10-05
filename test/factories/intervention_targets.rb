FactoryGirl.define do
  factory :intervention_target do
    reference_name 'land_parcel'
    product
    intervention

    factory :spraying_target do
      reference_name 'cultivation'
    end
  end
end
