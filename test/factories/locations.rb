FactoryBot.define do
  factory :location do
    registered_postal_zone_id { RegisteredPostalCode.order(Arel.sql('RANDOM()')).first.id }
    locality { FFaker::AddressFR.city }
    for_cvi_cadastral_plant

    trait :for_cvi_cadastral_plant do
      association :localizable, factory: :cvi_cadastral_plant
    end

    trait :for_cvi_cultivable_zone do
      association :localizable, factory: :cvi_cadastral_plant
    end

    trait :for_cvi_land_parcel do
      association :localizable, factory: :cvi_land_parcel
    end
  end
end
