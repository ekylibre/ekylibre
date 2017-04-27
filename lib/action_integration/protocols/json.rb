module ActionIntegration
  module Protocols
    # JSON protocol methods. Rely on Base.
    module JSON
      include Protocols::RestBase

      def get(path, headers = {}, &block)
        get_base(path, { 'Content-Type' => 'application/json' }.merge(headers), &block)
      end

      def post(path, data, headers = {}, &block)
        post_base(path, data, { 'Content-Type' => 'application/json' }.merge(headers), &block)
      end

      def put(path, data, headers = {}, &block)
        put_base(path, data, { 'Content-Type' => 'application/json' }.merge(headers), &block)
      end

      def patch(path, data, headers = {}, &block)
        patch_base(path, data, { 'Content-Type' => 'application/json' }.merge(headers), &block)
      end

      def delete(path, headers = {}, &block)
        delete_base(path, { 'Content-Type' => 'application/json' }.merge(headers), &block)
      end
    end
  end
end
