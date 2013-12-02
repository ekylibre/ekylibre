module ActiveList

  module Definition

    class AttributeColumn < DataColumn

      attr_reader :column, :label_method, :sort_column

      def initialize(table, name, options = {})
        super(table, name, options)
        @label_method = (options[:label_method] || @name).to_sym
        unless @sort_column = options[:sort]
          if @table.model.columns_definition[@label_method]
            @sort_column = @label_method 
          elsif @table.model.columns_definition[@name]
            @sort_column = @name
          else
            @sort_column = :id
          end
        end
        @column  = @table.model.columns_definition[@label_method.to_s]
      end

      # Code for rows
      def datum_code(record = 'record_of_the_death', child = false)
        code = ""
        if child
          if @options[:children].is_a?(FalseClass)
            code = "nil"
          else
            code = "#{record}.#{table.options[:children]}.#{@options[:children] || @label_method}"
          end
        else
          code = "#{record}.#{@label_method}"
        end
        return code.c
      end

      # Returns the class name of the used model
      def class_name
        return self.table.model.name
      end

      def enumerize?
        self.table.model.send(@label_method).send(:values)
        return true
      rescue
        return false
      end

      def sort_expression
        "#{@table.model.table_name}.#{@sort_column}"
      end

    end

  end
end
