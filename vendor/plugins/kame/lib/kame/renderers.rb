module Kame

  mattr_reader :renderer
  @@renderers = {}

  def self.register_renderer(name, renderer)
    raise ArgumentError.new("A renderer must be Kame::Renderer") unless renderer.is_a? Kame::Renderer
    @renderers[name] = renderer.new
  end

  class Renderer
    
    def build_data_code
      raise NotImplementedError.new("#{self.class.name}#build_table_code is not implemented.")
    end

  end

end
