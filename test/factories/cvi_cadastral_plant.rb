FactoryBot.define do
  factory :cvi_cadastral_plant do
    work_number { rand(5) }
    section { %w[A F G].sample }
    designation_of_origin_id { RegisteredQualityAndOriginSign.order('RANDOM()').first.id }
    vine_variety_id { RegisteredVineVariety.where(category: 'variety').order('RANDOM()').first.id }
    rootstock_id { RegisteredVineVariety.where(category: 'rootstock').order('RANDOM()').first.id }
    land_parcel_id { RegisteredCadastralParcel.order('RANDOM()').first.id }
    land_parcel_number { rand(10) }
    area_value { rand.round(2) }
    area_unit { :hectare }
    inter_vine_plant_distance_value { rand(30..100) }
    inter_vine_plant_distance_unit { :centimeter }
    inter_row_distance_value { rand(30..100) }
    inter_row_distance_unit { :centimeter }
    planting_campaign { FFaker::Time.between(10.years.ago, Date.today).year }
    state { %i[planted removed_with_authorization].sample }
    type_of_occupancy { %i[tenant_farming owner].sample }
    land_modification_date {Date.today-rand(10_000) }
    cvi_statement
    with_location

    trait :with_location do
      after(:create) do |resource|
        create(:location, localizable: resource)
      end
    end
  end
end
