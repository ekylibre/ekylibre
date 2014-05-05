module Backend::VisualizationsHelper

  # Example of how to use in HAML view:
  #   = visualization :vizu1 do |v|
  #     - v.background "openstreetmap.hot"
  #     - v.background "openweather.precipitations"
  #     - v.background "openweather.heat"
  #     - v.layer :layer1, ProductReading.where(...), :simple
  #     - v.control :fullscreen
  #     - v.control :layer_selector
  #     - v.control :background_selector
  #     - v.control :search  
  #
  class VisualizationConfiguration

    def initialize(data = {})
      @data = data
    end
   
    def background(name, provider_name)
      @data[:backgrounds] ||= []
      @data[:backgrounds] << {name: name, provider_name: provider_name}
      
    end

    def layer(name, *args)
      options = args.extract_options!
      data = args.shift
      
      options[:type] ||= args.shift || :simple
      @data[:layers] ||= {}.with_indifferent_access
      @data[:layers][name] = options
    end
    
    def datasets(name, datas = {})
      @data[:datasets] ||= {}.with_indifferent_access
      @data[:datasets][name] = datas
    end

    #def control(name, options = {})
     #@data[:controls] ||= {}.with_indifferent_access
      #@data[:controls][name] = options
    #end
    
    def control(name, options = {} )
      @data[:controls] ||= []
      @data[:controls] << {name: name, options: options}
      
    end

    def to_json
      @data.to_json
    end

  end
    
  def visualization(name, options = {}, html_options = {})
    config = VisualizationConfiguration.new(options)
    yield config
    return content_tag(:div, nil, data: {visualization: config.to_json})
  end

end
