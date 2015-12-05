require 'test_helper'

class Charta::GeoJSONTest < ActiveSupport::TestCase
  test 'all form of Geo JSON' do
    samples = []
    samples << {
      'type' => 'Feature',
      'geometry' => {
        'type' => 'Point',
        'coordinates' => [125.6, 10.1]
      },
      'properties' => {
        'name' => 'Dinagat Islands'
      }
    }

    samples << {
      'type' => 'Point',
      'coordinates' => [125.6, 10.1]
    }

    samples << {
      'type' => 'Feature',
      'geometry' => {
        'type' => 'Point',
        'coordinates' => [125.6, 10.1]
      },
      'properties' => {
        'name' => 'Dinagat Islands'
      }
    }

    samples << {
      'type' => 'LineString',
      'coordinates' => [
        [102.0, 0.0], [103.0, 1.0], [104.0, 0.0], [105.0, 1.0]
      ]
    }

    samples << {
      'type' => 'FeatureCollection',
      'features' => []
    }

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

    samples.each do |sample|
      geojson = Charta::GeoJSON.new(sample)
      assert geojson.valid?
      assert_equal 4326, geojson.srid
    end
  end
end
