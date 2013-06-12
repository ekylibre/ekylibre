module Ekylibre
  module DataSource
    class Base

      def key
        raise NotImplementedError
      end

      def to_xml
        raise NotImplementedError
      end

      def to_json
        raise NotImplementedError
      end

      def to_yaml
        raise NotImplementedError
      end

    end
  end
end
