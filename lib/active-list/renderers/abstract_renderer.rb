module ActiveList

  module Renderers

    class AbstractRenderer
      attr_reader :generator, :table

      def initialize(generator)
        @generator = generator
        @table = generator.table
      end

      def var_name(name)
        @generator.var_name(name)
      end

      def remote_update_code
        raise NotImplementedError, "#{self.class.name}#remote_update_code is not implemented."
      end

      def build_data_code
        raise NotImplementedError, "#{self.class.name}#build_table_code is not implemented."
      end

    end

  end

end
