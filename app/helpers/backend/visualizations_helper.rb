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
    
    # def layer(name, list = {})
    #   @data[:layers] ||= []
    #   @data[:layers] << {name: name, list: list}
    # end
    
    def layer(name, data, options = {})
      data = data.compact.collect do |item|
        next unless item[:shape]
        item.merge(shape: Charta::Geometry.new(item[:shape]).transform(:WGS84).to_geojson).merge(item[:popup] ? {popup: compile_visualization_popup(item[:popup], item)} : {})
      end.compact
      @data[:layers] ||= []
      @data[:layers] << {reference: name}.merge(options.merge(name: name, data: data))
    end
    
    def choropleth(name, data, options = {})
      layer(name, data, options.merge(type: :choropleth))
    end
    
    def bubbles(name, data, options = {})
      layer(name, data, options.merge(type: :bubbles))
    end
    
    def categories(name, data, options = {})
      layer(name, data, options.merge(type: :categories))
    end
    
    def dataset(name, data)
      @data[:datasets] ||= {}.with_indifferent_access
      @data[:datasets][name] = data
    end

    def control(name, options = true)
      @data[:controls] ||= {}.with_indifferent_access
      @data[:controls][name.to_s.camelize(:lower)] = options
    end

    def to_json
      @data.jsonize_keys.to_json
    end

    protected

    def compile_visualization_popup(object, item)
      if object.is_a?(TrueClass)
        hash = {header: item[:name]}
        for key, value in item
          unless [:header, :footer, :name, :shape].include?(key)
            hash[key] = value.to_s
          end
        end
        compile_visualization_popup(hash, item)
      elsif object.is_a?(String)
        return [{type: :content, content: object}]
      elsif object.is_a?(Hash)
        blocks = []
        if header = object[:header]
          if header.is_a? String
            blocks << {type: :header, content: header}
          elsif header.is_a? TrueClass
            blocks << {type: :header, content: item[:name]}
          elsif header.is_a? Hash
            blocks << header.merge(type: :header)
          else
            raise "Not implemented header for #{object.class}"
          end
        end
        if content = object[:content]
          if content.is_a? String
            blocks << {type: :content, content: content}
          elsif content.is_a? Hash
            for attribute, value in content
              block = {}
              if value.is_a? String
                block.update(content: value)
              elsif value.is_a? Hash
                block.update(value)
              elsif value.is_a? TrueClass
                block.update(value: item[attribute].to_s, label: true)
              else
                raise "Not implemented block for #{object.class}"
              end        
              if block[:label].is_a?(TrueClass)
                block[:label] = "attributes.#{attribute}".t(default: ["labels.#{attribute}".to_sym, attribute.to_s.humanize])
              elsif !block[:label]
                block.delete(:label)
              end
              blocks << block.merge(type: :content)
            end
          else
            raise "Not implemented content for #{object.class}"
          end
        end
        if footer = object[:footer]
          if footer.is_a? String
            blocks << {type: :footer, content: footer}
          elsif footer.is_a? TrueClass
            blocks << {type: :footer, content: item[:name]}
          elsif footer.is_a? Hash
            blocks << footer.merge(type: :footer)
          else
            raise "Not implemented footer for #{object.class}"
          end
        end
        return blocks
      else
        raise "Not implemented for #{object.class}"
      end
    end


  end
  
  def visualization(name, options = {}, html_options = {})
    config = VisualizationConfiguration.new(options)
    yield config
    return content_tag(:div, nil, data: {visualization: config.to_json})
  end



end
