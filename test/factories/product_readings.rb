FactoryBot.define do
  factory :product_reading do
    read_at { Time.now }

    trait :boolean do
      indicator_name     { 'healthy' }
      boolean_value      { true }
      indicator_datatype { :boolean }
    end

    trait :choice do
      indicator_name     { 'certification' }
      choice_value       { 'cognac' }
      indicator_datatype { :choice }
    end

    trait :decimal do
      indicator_name     { 'members_population' }
      decimal_value      { 12.5 }
      indicator_datatype { :decimal }
    end

    # # At the time we do not have a single geometry-datatyped indicator
    # trait :geometry do
    #   indicator_name     ''
    #   geometry_value     ''
    #   indicator_datatype :geometry
    # end

    trait :integer do
      indicator_name     { 'rows_count' }
      integer_value      { 5 }
      indicator_datatype { :integer }
    end

    trait :measure do
      indicator_name     { 'diameter' }
      measure_value      { 5.in :meter }
      indicator_datatype { :measure }
    end

    trait :multi_polygon do
      indicator_name      { 'shape' }
      multi_polygon_value { Charta.new_geometry('SRID=4326;MULTIPOLYGON(((-0.792698263903731 45.822036886905,-0.792483687182539 45.8222985746827,-0.792043804904097 45.8220069796521,-0.792430043002241 45.8215882764244,-0.792698263903731 45.822036886905)))') }
      indicator_datatype  { :multi_polygon }
    end

    trait :point do
      indicator_name     { 'geolocation' }
      point_value        { Charta.new_geometry('SRID=4326;POINT(-0.783801558989031 45.8279122127986)') }
      indicator_datatype { :point }
    end

    trait :string do
      indicator_name     { 'witness' }
      string_value       { 'John' }
      indicator_datatype { :string }
    end
  end
end
