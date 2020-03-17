FactoryBot.define do
  factory :intervention_target do
    reference_name { 'land_parcel' }
    association :product, factory: :land_parcel
    intervention

    trait :with_cultivation do
      reference_name { :cultivation }
      working_zone { Charta.new_geometry("SRID=4326;MultiPolygon (((-1.017533540725708 44.23605999218229, -1.0204195976257324 44.236744122959124, -1.0197114944458008 44.238758034804555, -1.0165786743164062 44.238143107200145, -1.017533540725708 44.23605999218229)))") }
    end
  end
end
