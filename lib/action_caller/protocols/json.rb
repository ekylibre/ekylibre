module ActionCaller
  module Protocols
    # JSON protocol methods. Rely on Base.
    module JSON
      include Protocols::Base

      def get(path, &block)
        get_base(path, &block)
      end

      def post(path, data, &block)
        post_base(path, data, &block)
      end

      def put(path, data, &block)
        put_base(path, data, &block)
      end

      def patch(path, data, &block)
        patch_base(path, data, &block)
      end

      def delete(path, &block)
        delete_base(path, &block)
      end
    end
  end
end
