module Backend::VisualizationsHelper
  
  class VisualizationConfiguration  
    
    def initialize(config = {})
      @config = config
      @categories_colors = @config.delete(:categories_colors)
    end
    
    def background(name, options = {})
      options[:name] = name
      options[:provider] ||= options[:name]
      options[:label] ||= options[:name].humanize
      @config[:backgrounds] ||= []
      @config[:backgrounds] << options
    end
    
    def overlay(name, provider_name)
      @config[:overlays] ||= []
      @config[:overlays] << {name: name, provider_name: provider_name}
    end
    
    # def layer(name, list = {})
    #   @config[:layers] ||= []
    #   @config[:layers] << {name: name, list: list}
    # end
    
    def layer(name, serie, options = {})
      options[:label] ||= name.tl(default: "attributes.#{name}".to_sym)
      @config[:layers] ||= []
      @config[:layers] << {reference: name.to_s.camelcase(:lower)}.merge(options.merge(name: name, serie: serie.to_s.camelcase(:lower)))
    end
    
    def choropleth(name, serie, options = {})
      layer(name, serie, options.merge(type: :choropleth))
    end
    
    def bubbles(name, serie, options = {})
      layer(name, serie, options.merge(type: :bubbles))
    end
    
    def categories(name, serie, options = {})
      layer(name, serie, {colors: @categories_colors}.merge(options.merge(type: :categories)))
    end

    # Add a serie of geo data
    def serie(name, data)
      @config[:series] ||= {}.with_indifferent_access
      @config[:series][name] = data.compact.collect do |item|
        next unless item[:shape]
        item
          .merge(shape: Charta::Geometry.new(item[:shape]).transform(:WGS84).to_geojson)
          .merge(item[:popup] ? {popup: compile_visualization_popup(item[:popup], item)} : {})
      end.compact
    end

    # Add a control
    def control(name, options = true)
      @config[:controls] ||= {}.with_indifferent_access
      @config[:controls][name.to_s.camelize(:lower)] = options
    end

    def to_json
      @config.jsonize_keys.to_json
    end

    protected

    # Build a data structure for popup building
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
          blocks << compile_block(header, :header, content: item[:name])
        end
        if content = object[:content]
          if content.is_a? String
            blocks << {type: :content, content: content}
          elsif content.is_a? Array
            for value in content
              block = {}
              if value.is_a? String
                block.update(content: value)
              elsif value.is_a? Hash
                block.update(value)
              else
                raise "Not implemented array block for #{object.class}"
              end        
              if block[:label].is_a?(TrueClass)
                block[:label] = "attributes.#{attribute}".t(default: ["labels.#{attribute}".to_sym, attribute.to_s.humanize])
              elsif !block[:label]
                block.delete(:label)
              end
              blocks << block.merge(type: :content)
            end
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
                raise "Not implemented hash block for #{object.class}"
              end        
              if block[:label].is_a?(TrueClass)
                block[:label] = "attributes.#{attribute}".t(default: ["labels.#{attribute}".to_sym, attribute.to_s.humanize])
              elsif !block[:label]
                block.delete(:label)
              end
              blocks << block.merge(type: :content)
            end
          else
            raise "Not implemented content for #{content.class}"
          end
        end
        if footer = object[:footer]
          blocks << compile_block(footer, :footer, content: item[:name])
        end
        return blocks
      else
        raise "Not implemented for #{object.class}"
      end
    end


    def compile_block(*args)
      options = args.extract_options!
      info = args.shift
      type = args.shift || options[:type]
      if info.is_a? String
        block = {type: type, content: info}
      elsif info.is_a? TrueClass
        if options[:content]
          block = {type: type, content: options[:content]}
        else
          raise StandardError, "Option :content must be given when info is a TrueClass"
        end
      elsif info.is_a? Hash
        block = info.merge(type: type)
      else
        raise StandardError, "Not implemented #{type} for #{object.class}"
      end
      return block
    end


  end
  

  # Example of how to use in HAML view:
  #
  #   = visualization do |v|
  #     - v.serie :data, <data>
  #     - v.background "openstreetmap.hot"
  #     - v.background "openweather.precipitations"
  #     - v.background "openweather.heat"
  #     - v.choropleth :<property>, :data
  #     - v.control :fullscreen
  #     - v.control :layer_selector
  #     - v.control :background_selector
  #     - v.control :search  
  #
  def visualization(options = {}, html_options = {})
    config = VisualizationConfiguration.new({categories_colors: theme_colors}.merge(options))
    yield config
    return content_tag(:div, nil, html_options.deep_merge(data: {visualization: config.to_json}))
  end



end
