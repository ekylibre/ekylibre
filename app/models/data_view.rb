class DataView
  
  class Builder < Nokogiri::XML::Builder
    # Produce JSON from defined source
    def to_json
      # Not really beautiful but it does the job
      Hash.from_xml(@builder.to_xml).to_json
    end

    # Produce HTML from defined source
    def to_html
      self.class.hash_to_html(Hash.from_xml(@builder.to_xml))
    end

    protected

    def self.hash_to_haml(hash, options = {})
      return unless hash.is_a?(Hash)
      html = "<ul>"
      for key, value in hash
        html << "<li><strong>#{key}</strong>"
        html << (value.is_a?(Hash) ? hash_to_html(value) : " <span>#{value}</span>")
        html << "</li>"
      end
      html << "</ul>"
      return html
    end

  end

  class SemanticBuilder
    # Produce JSON from defined source
    def list(name, attributes = {}, &block)
    end

    def value(name, label = nil, attributes = {}, &block)
    end

    def table(name, options = {}, &block)
    end

    def title(name)
    end

  end


  # attr_accessor :builders

  class << self

    # Instantiate a view with given parameters
    def build(*args)      
      return new.build(*args)
    end

    # Register __build__ method
    def define_view(&view)
      raise ArgumentError.new("Needs one argument at least") unless view.arity >= 1
      define_method(:build) do |*args|
        @builder = Builder.new do |xml|
          view.call(xml, *args)
        end
        return self
      end
      # define_method(:__build__, &block)
    end

  end

  def to_xml
    @builder.to_xml
  end

  def to_json
    @builder.to_json
  end

  def to_html
    @builder.to_html
  end

end


