module Autocastable
  extend ActiveSupport::Concern

  included do
    class << self
      prepend KlassMethods
    end
  end

  module KlassMethods
    # Auto-cast product to best matching class with type column
    def new(*attributes, &block)
      if (h = attributes.first).is_a?(Hash) && !h.nil? && (type = h[:type] || h['type']) && !type.empty? && (klass = type.constantize) != self
        raise "Can not cast #{name} to #{klass.name}" unless klass <= self
        return klass.new(*attributes, &block)
      end

      super(*attributes, &block)
    end
  end

end