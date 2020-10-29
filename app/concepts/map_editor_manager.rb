class MapEditorManager
  class << self
    LAYERS = {
      land_parcels: {
        label: [:land_parcels],
        name: :land_parcels,
        serie: :land_parcels_serie,
        type: :simple
      },
      plants: {
        label: [:plants],
        name: :plants,
        serie: :plants_serie,
        reference: 'variety',
        stroke: 2,
        fillOpacity: 0.7,
        type: :categories
      }
    }

    RegisteredPhytosanitaryUsage::UNTREATED_BUFFER_AQUATIC_VALUES.each do |n|
      LAYERS[:"aquatic_nta_#{n}"] = { label: [:aquatic_nta, distance: n], name: :"aquatic_nta_#{n}", serie: :"aquatic_nta_#{n}_serie", type: :optional, bounds_buffer: true }
    end

    LAYERS.freeze

    def shapes(options = {})
      options[:layers] ||= []
      options[:started_at] ||= DateTime.now
      mapeditor = {}
      mapeditor[:show] ||= {}
      mapeditor[:show][:series] ||= {}
      mapeditor[:show][:layers] ||= []

      options[:layers].map(&:to_sym).each do |layer|
        next unless LAYERS.keys.include? layer

        layer_serie = "#{layer}_serie"
        layer_label = LAYERS[layer][:label]
        mapeditor[:show][:series][layer_serie] = send(layer_serie, options)
        mapeditor[:show][:layers] << LAYERS[layer].merge(label: layer_label.first.send(:tl, layer_label.second))
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

    def aquatic_nta_serie(distance, options)
      return Charta::GeometryCollection.empty.to_json_feature_collection if options[:bounding_box].blank?

      hydro_items = RegisteredHydroItem.in_bounding_box(options[:bounding_box]).map do |item|
        [item.geometry.buffer(distance).to_text, { name: item.name, nature: item.nature }]
      end

      shapes = hydro_items.collect(&:first)
      properties = hydro_items.collect(&:second)

      collection = Charta.new_geometry("GEOMETRYCOLLECTION(#{shapes.join(',')})")
      collection.to_json_feature_collection(properties)
    end

    RegisteredPhytosanitaryUsage::UNTREATED_BUFFER_AQUATIC_VALUES.each do |n|
      define_method(:"aquatic_nta_#{n}_serie") { |options = {}| aquatic_nta_serie(n, options) }
    end
  end
end
