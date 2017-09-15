class MapEditorManager

  class << self

    LAYERS = {
        land_parcels: {
            name: :land_parcels,
            label: :land_parcels.tl,
            serie: :land_parcels_serie,
            type: :simple
        },
        plants: {
            name: :plants,
            label: :plant.tl,
            serie: :plants_serie,
            reference: 'variety',
            stroke: 2,
            fillOpacity: 0.7,
            type: :categories
        }
    }

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
        mapeditor[:show][:layers] << LAYERS[sym_layer]

      end
      mapeditor
    end

    def land_parcels_serie(options = {})
      land_parcels = LandParcel.at(options[:started_at]).collect do |l|
        next if l.shape.nil?
        {shape: l.shape}
      end.compact

      Charta.new_collection(land_parcels).to_json_object(true)
    end

    def plants_serie(options = {})
      plants = Plant.at(options[:started_at]).collect do |l|
        next if l.shape.nil?
        {name: l.name, shape: l.shape, variety: Nomen::Variety[l.variety].human_name, color: Activity.color(:plant_farming, l.variety), fillColor: Activity.color(:plant_farming, l.variety)}
      end.compact

      Charta.new_collection(plants).to_json_object(true)
    end
  end
end
