module ActiveList

  module Definition

    class AttributeColumn < DataColumn

      attr_reader :column

      def initialize(table, name, options = {})
        super(table, name, options)
        @column  = @table.model.columns_definition[@name.to_s]
      end

      # Code for rows
      def datum_code(record = 'record_of_the_death', child = false)
        code = ""
        if child 
          if @options[:children].is_a?(FalseClass)
            code = "nil"
          else
            code = "#{record}.#{table.options[:children]}.#{@options[:children] || @name}"
          end
        else
          code = "#{record}.#{@name}"
        end
        return code.c
      end

      def label_method
        @name
      end

      # Returns the class name of the used model
      def class_name
        return self.table.model.name
      end

    end

  end
end
