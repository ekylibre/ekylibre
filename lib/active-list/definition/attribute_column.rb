module ActiveList

  module Definition

    class AttributeColumn < DataColumn

      attr_reader :column, :label_method

      def initialize(table, name, options = {})
        super(table, name, options)
        @label_method = (options[:label_method] || @name).to_sym
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


    end

  end
end
