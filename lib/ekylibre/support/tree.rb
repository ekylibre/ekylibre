module Ekylibre
  module Support
    class Tree < HashWithIndifferentAccess

      def [](*keys)
        key = keys.shift
        object = self.fetch(key)
        if keys.any?
          return (object.is_a?(Tree) ? object[*keys] : nil)
        end
        return object
      end


      def []=(*args)

      end

    end
  end
end
