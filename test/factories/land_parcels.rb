FactoryBot.define do
  factory :land_parcel do
    initial_shape { Charta.new_geometry("SRID=4326;MultiPolygon (((-1.017533540725708 44.23605999218229, -1.0204195976257324 44.236744122959124, -1.0197114944458008 44.238758034804555, -1.0165786743164062 44.238143107200145, -1.017533540725708 44.23605999218229)))") }
    born_at { DateTime.new(2017, 6, 1) }

    association :category, factory: :land_parcel_category
    association :nature, factory: :land_parcel_nature
    association :variant, factory: :land_parcel_variant
    variety { 'land_parcel' }

    transient do
      production_name { :corn_activity_production }
    end

    after(:build) do |land_parcel, evaluator|
      land_parcel.activity_production = create *evaluator.production_name, support: land_parcel, started_on: land_parcel.born_at&.to_date
    end

    factory :lemon_land_parcel do
      transient do
        production_name { :lemon_activity_production }
      end

      trait :organic do
        transient do
          production_name { %i[lemon_activity_production organic] }
        end
      end
    end
  end
end
