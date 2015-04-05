module Ekylibre
  module Parts

    class Page

      attr_reader :controller, :action, :path

      def initialize(to)
        @path = to
        @controller, @action = @path.split("#")[0..1]
      end

      def to_hash
        {controller: "/" + @controller, action: @action}
      end

      def ==(other)
        @path == other.path
      end

      def human_name
        "actions.#{@controller}.#{@action}".t
      end

    end

  end
end
