# frozen_string_literal: true

module Ekylibre
  class Plugin
    class Base
      # @return [String]
      def name
        *start, _last = self.class.name.lower.split('::')

        start.join('::')
      end

      # @return [Array<String>]
      def themes
        []
      end
    end
  end
end
