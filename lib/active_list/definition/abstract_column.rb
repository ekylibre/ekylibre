module ActiveList

  module Definition

    class AbstractColumn
      attr_reader :table, :name, :id, :options

      def initialize(table, name, options = {})
        @table   = table
        @name    = name.to_sym
        @options = options
        @hidden  = !!@options.delete(:hidden)
        @id = ActiveList.new_uid
      end

      def header_code
        raise NotImplementedError, "#{self.class.name}#header_code is not implemented."
      end

      def hidden?
        @hidden
      end

      def sortable?
        false
      end

      def exportable?
        false
      end

      # Unique identifier of the column in the application
      def unique_id
        "#{@table.name}-#{@name}"
      end

      # Uncommon but simple identifier for CSS class uses
      def short_id
        @id
      end

      alias :sort_id :name

      def check_options!(options, *keys)
        for key in options.keys
          raise ArgumentError, "Key :#{key} is unexpected. (Expecting: #{keys.to_sentence})"
        end
      end

    end

  end

end
