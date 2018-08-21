FactoryBot.define do
  factory :land_parcel do
    shape = '{
              "type": "Feature",
              "properties": {},
              "geometry": {
                "type": "Polygon",
                "coordinates": [
                  [
                    [
                      2.2214162349700928,
                      45.89087440253303
                    ],
                    [
                      2.220107316970825,
                      45.88891786700034
                    ],
                    [
                      2.2223711013793945,
                      45.88809640024204
                    ],
                    [
                      2.2246885299682617,
                      45.88996335257688
                    ],
                    [
                      2.223111391067505,
                      45.8900679000522
                    ],
                    [
                      2.2214162349700928,
                      45.89087440253303
                    ]
                  ]
                ]
              }
            }'
    initial_shape { Charta.new_geometry(shape) }
    association :category, factory: :product_nature_category
    association :nature, factory: :land_parcel_nature
    association :variant, factory: :land_parcel_nature_variant
    variety { 'land_parcel' }
  end
end
