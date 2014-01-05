# require 'active_support/core_ext/module/attribute_accessors'

module ActiveList

  module Renderers

    def self.[](name)
      ActiveList.renderers[name]
    end

    autoload :AbstractRenderer, 'active_list/renderers/abstract_renderer'
    autoload :SimpleRenderer,   'active_list/renderers/simple_renderer'
  end

  mattr_reader :renderers
  @@renderers = {}

  def self.register_renderer(name, renderer)
    raise ArgumentError.new("A renderer must be ActiveList::Renderers::Renderer") unless renderer < ActiveList::Renderers::AbstractRenderer
    @@renderers[name] = renderer
  end

end

ActiveList.register_renderer(:simple_renderer, ActiveList::Renderers::SimpleRenderer)
