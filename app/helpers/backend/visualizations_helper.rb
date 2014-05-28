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
  COLORS = ['#2f7ed8', '#0d233a', '#8bbc21', '#910000', '#1aadce', '#492970',
    '#f28f43', '#77a1e5', '#c42525', '#a6c96a']
    
  def lighten(color, rate)
    r, g, b = color[1..2].to_i(16), color[3..4].to_i(16), color[5..6].to_i(16)
    r *= (1+rate)
    g *= (1+rate)
    b *= (1+rate)
    r = 255 if r > 255
    g = 255 if g > 255
    b = 255 if b > 255
    return '#' + r.to_i.to_s(16).rjust(2, '0') + g.to_i.to_s(16).rjust(2, '0') + b.to_i.to_s(16).rjust(2, '0')
  end
    
    
  class VisualizationConfiguration  
     
    def initialize(data = {})
      @data = data
    end
   
    def background(name, provider_name)
      @data[:backgrounds] ||= []
      @data[:backgrounds] << {name: name, provider_name: provider_name}
      
    end
    
    def overlay(name, provider_name)
      @data[:overlays] ||= []
      @data[:overlays] << {name: name, provider_name: provider_name}
      
    end
  
    def layer(name, list = {})
      @data[:layers] ||= []
      @data[:layers] << {name: name, list: list}

    end
    
    def datasets(name, datas = {})
      @data[:datasets] ||= {}.with_indifferent_access
      @data[:datasets][name] = datas
    end

    #def control(name, options = {})
     #@data[:controls] ||= {}.with_indifferent_access
      #@data[:controls][name] = options
    #end
    
    def control(name )
      @data[:controls] ||= []
      @data[:controls] << {name: name}
      
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
