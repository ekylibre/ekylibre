module Map
  module BaseHelper
    include CartographyHelper

    def map_config(options = {})
      {
        controls: {
          zoom: true,
          home: false,
          layers: true
        },
        box: {
          width: '100%',
          height: '100%'
        },
        backgrounds: backgrounds,
        defaultCenter: {
          lat: 46.74738913515841,
          lng: 2.493896484375
        }
      }.merge(options.compact)
    end

    def backgrounds
      MapLayer.available_backgrounds.map { |e| e.attributes.transform_keys { |k| k.camelize(:lower) } }
    end
  end
end
