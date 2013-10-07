require 'active_support/core_ext/module/attribute_accessors'

module ActiveList

  mattr_reader :renderers
  @@renderers = {}

  def self.register_renderer(name, renderer)
    raise ArgumentError.new("A renderer must be ActiveList::Renderer") unless renderer.ancestors.include? ActiveList::Renderer
    @@renderers[name] = renderer
  end

  class Renderer
    attr_reader :table

    def initialize(table)
      @table = table
    end

    def var_name(name)
      @table.var_name(name)
    end

    def remote_update_code
      raise NotImplementedError.new("#{self.class.name}#remote_update_code is not implemented.")
    end

    def build_data_code
      raise NotImplementedError.new("#{self.class.name}#build_table_code is not implemented.")
    end

  end

end


require "active-list/renderers/simple_renderer"
