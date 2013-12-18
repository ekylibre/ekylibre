module Ekylibre
  module Support
    class Item < Struct.new(:name, :args, :block)
    end

    class Lister
      
      def initialize(type = :items)
        @items = []
        @type = type
        code  = "def #{@type.to_s}\n"
        code << "  @items\n"
        code << "end"
        eval(code)
      end
      
      def method_missing(method_name, *args, &block)
        @items << Item.new(method_name.to_sym, args, block)
        return nil
      end
    end

  end
end
