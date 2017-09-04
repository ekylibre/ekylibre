module Ekylibre
  module Support
    class Tree < HashWithIndifferentAccess
      def [](*keys)
        key = keys.shift
        object = fetch(key)
        return (object.is_a?(Tree) ? object[*keys] : nil) if keys.any?
        object
      end

      def []=(*_args); end
    end
  end
end
