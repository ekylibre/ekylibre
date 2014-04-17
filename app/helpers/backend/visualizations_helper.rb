module Backend::VisualizationHelper

  #visualization :vizu1 do |v|
  #  v.background "openstreetmap.hot"
  #  v.background "openweather.precipitations"
  #  v.background "openweather.heat"
  #  v.layer :layer1, ProductReading.where(), :simple
  #  v.layer :layer2
  #  v.controll :fullscreen
  #  v.controll :layer_selector
  #  v.controll :background_selector
  #  v.controll :
  #  v.controll :search
  #end
  
  class VisualizationConfig
    
    def initialize ()
    end
  end
    
  def visualization(name)
    config = VisualizationConfig.new
    yield config
    content_tag(:div, nil, data: {visualization: config.to_json})
  end

end