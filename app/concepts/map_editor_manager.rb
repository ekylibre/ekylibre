class MapEditorManager
  class << self
    LAYERS = {
      land_parcels: {
        name: :land_parcels,
        serie: :land_parcels_serie,
        type: :simple
      },
      plants: {
        name: :plants,
        serie: :plants_serie,
        reference: 'variety',
        stroke: 2,
        fillOpacity: 0.7,
        type: :categories
      }
    }.freeze

    def shapes(options = {})
      options[:layers] ||= []
      options[:started_at] ||= DateTime.now
      mapeditor = {}
      mapeditor[:show] ||= {}
      mapeditor[:show][:series] ||= {}
      mapeditor[:show][:layers] ||= []

      if options[:bounding_box].present?
      end

      options[:layers].each do |layer|
        sym_layer = layer.to_sym
        next unless LAYERS.keys.include? sym_layer

        layer_serie = "#{sym_layer}_serie"
        mapeditor[:show][:series][layer_serie] = send(layer_serie, options)
        mapeditor[:show][:layers] << LAYERS[sym_layer].merge(label: sym_layer.tl)
      end
      mapeditor
    end

    def land_parcels_serie(options = {})
      land_parcels = LandParcel.at(options[:started_at]).collect do |l|
        next unless l.shape

        [l.shape.to_text, {}]
      end.compact

      shapes = land_parcels.collect(&:first)
      properties = land_parcels.collect(&:second)

      collection = Charta.new_geometry("GEOMETRYCOLLECTION(#{shapes.join(',')})")
      collection.to_json_feature_collection(properties)
    end

    def plants_serie(options = {})
      plants = Plant.at(options[:started_at]).collect do |l|
        next unless l.shape

        [l.shape.to_text, { name: l.name, variety: Nomen::Variety[l.variety].human_name, color: Activity.color(:plant_farming, l.variety), fillColor: Activity.color(:plant_farming, l.variety) }]
      end.compact

      shapes = plants.collect(&:first)
      properties = plants.collect(&:second)

      collection = Charta.new_geometry("GEOMETRYCOLLECTION(#{shapes.join(',')})")
      collection.to_json_feature_collection(properties)
    end
  end
end
