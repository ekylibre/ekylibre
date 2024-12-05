# frozen_string_literal: true

class MapEditorManager
  class << self
    LAYERS = begin
               layers = {
                 land_parcels: {
                   label: [:land_parcels].freeze,
                   name: :land_parcels,
                   serie: :land_parcels_serie,
                   type: :simple
                 }.freeze,
                 plants: {
                   label: [:plants].freeze,
                   name: :plants,
                   serie: :plants_serie,
                   reference: 'variety',
                   stroke: 2,
                   fillOpacity: 0.7,
                   type: :categories
                 }.freeze,
                 cultivable_zones: {
                   label: [:cultivable_zones].freeze,
                   name: :cultivable_zones,
                   serie: :cultivable_zones_serie,
                   fillOpacity: 0.5,
                   type: :simple
                 }.freeze,
                 cadastral_parcels: {
                   label: [:cadastral_parcels].freeze,
                   name: :cadastral_parcels,
                   serie: :cadastral_parcels_serie,
                   fillOpacity: 0.2,
                   type: :optional,
                   bounds_buffer: true
                 }.freeze
               }

               RegisteredPhytosanitaryUsage::UNTREATED_BUFFER_AQUATIC_VALUES.each do |n|
                 layers[:"aquatic_nta_#{n}"] = { label: [:aquatic_nta, distance: n], name: :"aquatic_nta_#{n}", serie: :"aquatic_nta_#{n}_serie", type: :optional, bounds_buffer: true }
               end

               layers
             end.freeze

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
        mapeditor[:show][:layers] << LAYERS[layer].merge(label: layer_label.first.tl(**layer_label.second || {}))
      end
      mapeditor
    end

    def cultivable_zones_serie(options = {})
      cultivable_zones = CultivableZone.all.collect do |l|
        next if l.shape.nil?

        [l.shape.to_text, { name: l.name }]
      end.compact

      shapes = cultivable_zones.collect(&:first)
      properties = cultivable_zones.collect(&:second)

      collection = Charta.new_geometry("GEOMETRYCOLLECTION(#{shapes.join(',')})")
      collection.to_json_feature_collection(properties)
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
        next if l.shape.nil? || l.variety.nil?

        [l.shape.to_text, { name: l.name, variety: Onoma::Variety[l.variety].human_name, color: Activity.color(:plant_farming, l.variety), fillColor: Activity.color(:plant_farming, l.variety) }]
      end.compact

      shapes = plants.collect(&:first)
      properties = plants.collect(&:second)

      collection = Charta.new_geometry("GEOMETRYCOLLECTION(#{shapes.join(',')})")
      collection.to_json_feature_collection(properties)
    end

    def cadastral_parcels_serie(options = {})
      return Charta::GeometryCollection.empty.to_json_feature_collection if options[:bounding_box].blank?

      cadastral_items = RegisteredCadastralParcel.in_bounding_box(options[:bounding_box]).map do |item|
        [item.shape.to_text, { name: item.label }]
      end

      shapes = cadastral_items.collect(&:first)
      properties = cadastral_items.collect(&:second)

      collection = Charta.new_geometry("GEOMETRYCOLLECTION(#{shapes.join(',')})")
      collection.to_json_feature_collection(properties)
    end

    def aquatic_nta_serie(distance, options)
      return Charta::GeometryCollection.empty.to_json_feature_collection if options[:bounding_box].blank?

      hydro_items = RegisteredHydrographicItem.in_bounding_box(options[:bounding_box]).map do |item|
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
