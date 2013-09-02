require 'active_support/core_ext/module/attribute_accessors'

module ActiveList

  mattr_reader :renderers
  @@renderers = {}

  def self.register_renderer(name, renderer)
    raise ArgumentError.new("A renderer must be ActiveList::Renderer") unless renderer.ancestors.include? ActiveList::Renderer
    @@renderers[name] = renderer.new
  end

  class Renderer
    
    def remote_update_code(table)
      raise NotImplementedError.new("#{self.class.name}#remote_update_code is not implemented.")
    end

    def build_data_code(table)
      raise NotImplementedError.new("#{self.class.name}#build_table_code is not implemented.")
    end

  end

end


require "active-list/renderers/simple_renderer"
