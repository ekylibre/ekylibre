module Ekylibre
  module Record
    class Column
      attr_reader :name, :type, :limit, :default, :precision, :scale, :options

      def initialize(name, type, options = {})
        @name = name.to_sym
        @type = type.to_sym
        @options = options.merge(name: @name, type: @type)
        @null      = !@options[:null].is_a?(FalseClass)
        @default   = @options[:default]
        @limit     = @options[:limit]
        @precision = @options[:precision]
        @scale     = @options[:scale]
      end

      def [](value)
        @options[value]
      end

      def null?
        @null
      end

    end
  end
end
