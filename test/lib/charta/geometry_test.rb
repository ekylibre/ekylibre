# encoding: UTF-8
require 'test_helper'

class Charta::GeometryTest < ActiveSupport::TestCase
  test 'different E/WKT format input' do
    samples = ['POINT(6 10)',
               'LINESTRING(3 4,10 50,20 25)',
               'POLYGON((1 1,5 1,5 5,1 5,1 1))',
               'MULTIPOINT((3.5 5.6), (4.8 10.5))',
               'MULTILINESTRING((3 4,10 50,20 25),(-5 -8,-10 -8,-15 -4))',
               'MULTIPOLYGON(((1 1,5 1,5 5,1 5,1 1),(2 2,2 3,3 3,3 2,2 2)),((6 3,9 2,9 4,6 3)))',

               'GEOMETRYCOLLECTION(POINT(4 6),LINESTRING(4 6,7 10))',
               'POINT ZM (1 1 5 60)',
               'POINT M (1 1 80)',
               'POINT EMPTY',
               'MULTIPOLYGON EMPTY'
              ]

    samples.each_with_index do |sample, index|
      geom1 = Charta::Geometry.new(sample, :WGS84)
      geom2 = Charta::Geometry.new("SRID=4326;#{sample}")

      assert_equal geom1.to_ewkt, geom2.to_ewkt

      assert_equal geom1.srid, geom2.srid

      assert geom1 == geom2 if index <= 5
      assert geom1.area
    end

    assert Charta::Geometry.empty.empty?
  end

  test 'different GeoJSON format input' do
    samples = []
    samples << {
      'type' => 'FeatureCollection',
      'features' => []
    }

    # http://geojson.org/geojson-spec.html#examples
    samples << '{ "type": "FeatureCollection", "features": [   { "type": "Feature",     "geometry": {"type": "Point", "coordinates": [102.0, 0.5]},     "properties": {"prop0": "value0"}     },   { "type": "Feature",     "geometry": {       "type": "LineString",       "coordinates": [         [102.0, 0.0], [103.0, 1.0], [104.0, 0.0], [105.0, 1.0]         ]       },     "properties": {       "prop0": "value0",       "prop1": 0.0       }     },   { "type": "Feature",      "geometry": {        "type": "Polygon",        "coordinates": [          [ [100.0, 0.0], [101.0, 0.0], [101.0, 1.0],            [100.0, 1.0], [100.0, 0.0] ]          ]      },      "properties": {        "prop0": "value0",        "prop1": {"this": "that"}        }      }    ]  }'

    # http://geojson.org/geojson-spec.html#examples
    samples << '{ "type": "FeatureCollection", "features": [ { "type": "Feature", "geometry": {"type": "Point", "coordinates": [102.0, 0.5]}, "properties": {"prop0": "value0"} }, { "type": "Feature", "geometry": { "type": "LineString", "coordinates": [ [102.0, 0.0], [103.0, 1.0], [104.0, 0.0], [105.0, 1.0] ] }, "properties": { "prop0": "value0", "prop1": 0.0 } }, { "type": "Feature", "geometry": { "type": "Polygon", "coordinates": [ [ [100.0, 0.0], [101.0, 0.0], [101.0, 1.0], [100.0, 1.0], [100.0, 0.0] ] ] }, "properties": { "prop0": "value0", "prop1": {"this": "that"} } } ] }'

    # http://geojson.org/geojson-spec.html#examples
    samples << '{ "type": "FeatureCollection",
    "features": [
      { "type": "Feature",
        "geometry": {"type": "Point", "coordinates": [102.0, 0.5]},
        "properties": {"prop0": "value0"}
        },
      { "type": "Feature",
        "geometry": {
          "type": "LineString",
          "coordinates": [
            [102.0, 0.0], [103.0, 1.0], [104.0, 0.0], [105.0, 1.0]
            ]
          },
        "properties": {
          "prop0": "value0",
          "prop1": 0.0
          }
        },
      { "type": "Feature",
         "geometry": {
           "type": "Polygon",
           "coordinates": [
             [ [100.0, 0.0], [101.0, 0.0], [101.0, 1.0],
               [100.0, 1.0], [100.0, 0.0] ]
             ]
         },
         "properties": {
           "prop0": "value0",
           "prop1": {"this": "that"}
           }
         }
       ]
     }'

    samples.each_with_index do |sample, _index|
      geom = Charta::Geometry.new(sample)
      assert_equal 4326, geom.srid
    end
  end
end
