FactoryBot.define do
  factory :cvi_cultivable_zone do
    sequence(:name) { |n| "Zone#{n}" }
    declared_area_unit { :hectare }
    declared_area_value { rand.round(2) }
    land_parcels_status { %i[not_started started completed].sample }
    shape { FFaker::Shape.polygon.simplify(0.05) }
    cvi_statement
    with_location

    trait :with_location do
      after(:create) do |resource|
        create(:location, localizable: resource)
      end
    end

    trait :old_splitted do
      shape {'POLYGON ((-0.2532838 45.77936779560541, -0.252766 45.78065979560589, -0.25263 45.78060929560586, -0.2531422999999999 45.77933279560539, -0.2532838 45.77936779560541))'}
    end

    trait :new_splitted do
      sequence(:shape) do |n|
        [
          'POLYGON ((-0.2532838 45.77936779560541, -0.2530568 45.77993679560561, -0.2530234355964364 45.7800197476819, -0.2528854767532964 45.77997453204999, -0.2529129 45.77990639560561, -0.2531422999999999 45.77933279560539, -0.2532838 45.77936779560541))',
          'POLYGON ((-0.2530234355964364 45.7800197476819, -0.252766 45.78065979560589, -0.25263 45.78060929560586, -0.2528854767532964 45.77997453204999, -0.2530234355964364 45.7800197476819))'
        ][n % 2]
      end
    end

    trait :with_cvi_cadastral_plants do
      after(:create) do |cvi_cultivable_zone|
        create_list(:cvi_cadastral_plant, Random.rand(1..4), cvi_cultivable_zone: cvi_cultivable_zone)
      end
    end

    trait :with_cvi_land_parcels do
      after(:create) do |cvi_cultivable_zone|
        create_list(:cvi_land_parcel, Random.rand(1..4), cvi_cultivable_zone: cvi_cultivable_zone)
      end
    end

    trait :with_cvi_land_parcels_all_created do
      after(:create) do |cvi_cultivable_zone|
        activity = create(:activity)
        create_list(:cvi_land_parcel, Random.rand(1..4), activity: activity, cvi_cultivable_zone: cvi_cultivable_zone)
      end
    end

    trait :with_cvi_land_parcel_created do
      after(:create) do |cvi_cultivable_zone|
        activity = create(:activity, :perennial)
        create(:cvi_land_parcel, activity: activity, cvi_cultivable_zone: cvi_cultivable_zone)
      end
    end
  end
end
