FactoryBot.define do
  factory :crop_group_item do
    crop_group
    for_plant

    trait :for_land_parcel do
      association :crop, factory: :land_parcel
    end

    trait :for_plant do
      association :crop, factory: :plant
    end
  end
end
