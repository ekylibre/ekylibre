module List

  mattr_reader :renderers
  @@renderers = {}

  def self.register_renderer(name, renderer)
    raise ArgumentError.new("A renderer must be List::Renderer") unless renderer.ancestors.include? List::Renderer
    @@renderers[name] = renderer.new
  end

  class Renderer
    
    def remote_update_code(table)
      raise NotImplementedError.new("#{self.class.name}#remote_update_code is not implemented.")
    end

    def build_data_code
      raise NotImplementedError.new("#{self.class.name}#build_table_code is not implemented.")
    end

  end

end


require "list/renderers/simple_renderer"
