require 'test_helper'

class GeoJSONTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test 'parse json' do
    assert GeoJSON.parse('{"type": "FeatureCollection", "features": []}')
  end

  test 'parse json fails if geojson invalid' do
    refute GeoJSON.parse('{"type": "FeatureCollection"}')
  end

  test 'poly creates a Polygon' do
    poly = GeoJSON.poly
    assert_equal 'Polygon', poly['type']
  end

  test 'feat creates a Feature' do
    feat = GeoJSON.feat
    assert_equal 'Feature', feat['type']
  end

  test 'feat does strigify keys of properties' do
    feat = GeoJSON.feat({name: 'blah'})
    assert feat['properties'].key? 'name'
    refute feat['properties'].key? :name
  end

  test 'feat_collection creates a FeatureCollection' do
    fc = GeoJSON.feat_collection
    assert_equal 'FeatureCollection', fc['type']
  end

  test 'feat_collection has splat parameter and flatten if given arrays' do
    fc = GeoJSON.feat_collection GeoJSON.feat, GeoJSON.feat, [GeoJSON.feat]
    assert_equal 3, fc['features'].length
  end
end
