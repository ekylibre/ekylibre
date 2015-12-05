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
      geom1 = Charta.new_geometry(sample, :WGS84)
      geom2 = Charta.new_geometry("SRID=4326;#{sample}")

      assert_equal geom1.to_ewkt, geom2.to_ewkt

      assert_equal geom1.srid, geom2.srid

      assert geom1 == geom2 if index <= 5
      assert geom1.area
    end

    assert Charta.empty_geometry.empty?
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
      geom = Charta.new_geometry(sample)
      assert_equal 4326, geom.srid
    end
  end

  test 'different GML format input' do
    samples = []

    samples << '<gml:MultiSurface srsName="EPSG:2154">
  <gml:surfaceMember>
    <gml:Polygon xmlns:gml="http://www.opengis.net/gml">
      <gml:outerBoundaryIs>
        <gml:LinearRing>
          <gml:coordinates> 407307.0555,6529551.3646 407260.5151,6529576.8458 407239.0404,6529537.6039 407181.6257,6529572.7935 407176.7528,6529565.4424 407180.6996,6529574.6456 407169.4221,6529559.5514 407162.0488,6529542.6713 407156.6494,6529533.9075 407152.4748,6529529.1499 407146.7973,6529526.2284 407140.9526,6529525.978 407135.8596,6529528.9828 407133.7721,6529534.2413 407131.9353,6529538.1645 407130.1819,6529539.5 407126.3414,6529540.0008 407120.1626,6529539.5 407115.3201,6529537.914 407113.2328,6529533.3232 407113.2328,6529527.3135 407116.8989,6529509.5777 407125.4918,6529477.0837 407136.0907,6529442.9418 407188.5401,6529451.5411 407217.9593,6529454.3293 407238.3643,6529497.2081 407242.6406,6529504.6893 407248.472,6529506.1467 407283.059,6529496.4856 407275.5885,6529480.296 407248.169,6529430.302 407273.051,6529421.056 407279.5092,6529417.7912 407243.4074,6529345.4337 407235.3894,6529329.7666 407240.0713,6529321.1407 407250.6157,6529304.443 407258.4157,6529292.4747 407266.15,6529310.1125 407292.4624,6529364.7683 407330.3168,6529443.1431 407358.0462,6529499.9032 407341.5258,6529505.4083 407299.5688,6529520.9968 407296.1057,6529523.4567 407296.1057,6529526.7364 407307.0555,6529551.3646 </gml:coordinates>
        </gml:LinearRing>
      </gml:outerBoundaryIs>
    </gml:Polygon>
  </gml:surfaceMember>
</gml:MultiSurface>'

    samples.each_with_index do |sample, index|
      assert ::Charta::GML.valid?(sample), "GML ##{index} should be valid"
      geom = Charta.new_geometry(sample, nil, 'gml').transform(:WGS84)

      assert_equal 4326, geom.srid
    end
  end

  test 'different KML format input' do
    samples = []

    samples << '<MultiGeometry srsName="EPSG:2154" xmlns:gml="http://www.opengis.net/kml/2.2">
    <Polygon>
        <outerBoundaryIs>
          <LinearRing>
            <tessellate>1</tessellate>
            <coordinates>-0.6333554,44.8059247,0.0 -0.6347930000000002,44.80565070000001,0.0 -0.6340957000000002,44.8046611,0.0 -0.6328510999999999,44.80490470000001,0.0 -0.6333554,44.8059247,0.0</coordinates>
          </LinearRing>
        </outerBoundaryIs>
    </Polygon>
</MultiGeometry>'

    samples.each_with_index do |sample, index|
      assert ::Charta::KML.valid?(sample), "KML ##{index} should be valid"
      geom = Charta.new_geometry(sample, nil, 'kml').transform(:WGS84)
      assert_equal 4326, geom.srid
    end
  end

  test 'comparison and methods between 2 geometries' do
    samples = ['POINT(6 10)',
               'LINESTRING(3 4,10 50,20 25)',
               'POLYGON((1 1,5 1,5 5,1 5,1 1))',
               'MULTIPOINT((3.5 5.6), (4.8 10.5))',
               'MULTILINESTRING((3 4,10 50,20 25),(-5 -8,-10 -8,-15 -4))',
               'MULTIPOLYGON(((7.40679681301117 48.1167274678089,7.40882456302643 48.1158768860692,7.40882456302643 48.1158679325024,7.40678608417511 48.1167220957579,7.40679681301117 48.1167274678089)))',
               'GEOMETRYCOLLECTION(POLYGON((7.40882456302643 48.1158768860692,7.40679681301117 48.1167274678089,7.40678608417511 48.1167220957579,7.40882456302643 48.1158679325024,7.40882456302643 48.1158768860692)),POINT(4 6),LINESTRING(4 6,7 10))',
               'POINT EMPTY',
               'MULTIPOLYGON EMPTY'
              ].collect do |ewkt|
      Charta.new_geometry("SRID=4326;#{ewkt}")
    end
    last = samples.count - 1
    samples.each_with_index do |geom1, i|
      (i..last).each do |j|
        geom2 = samples[j]
        # puts "##{i} #{geom1.to_ewkt.yellow} ~ ##{j} #{geom2.to_ewkt.blue}"
        unless geom1.collection? && geom2.collection?
          if j == i || (geom1.empty? && geom2.empty?)
            assert_equal geom1, geom2, "#{geom1.to_ewkt} and #{geom2.to_ewkt} should be equal"
          else
            assert geom1 != geom2, "#{geom1.to_ewkt} and #{geom2.to_ewkt} should be different"
          end
        end
        geom1.merge(geom2)
        geom1.intersection(geom2)
        geom1.difference(geom2)
      end
    end
  end


  test 'class cast' do
    samples =  {
      'Point' => 'POINT(6 10)',
      'LineString' => 'LINESTRING(3 4,10 50,20 25)',
      'Polygon' => 'POLYGON((1 1,5 1,5 5,1 5,1 1))',
      'MultiPolygon' => 'MULTIPOLYGON(((1 1,5 1,5 5,1 5,1 1),(2 2,2 3,3 3,3 2,2 2)),((6 3,9 2,9 4,6 3)))',
      'GeometryCollection' => 'GEOMETRYCOLLECTION(POINT(4 6),LINESTRING(4 6,7 10))'
    }
    samples.each do |class_name, ewkt|
      assert_equal 'Charta::' + class_name, Charta.new_geometry(ewkt).class.name
    end
  end

end
