module ActiveList

  module Definition

    class FieldColumn < AbstractColumn
      attr_reader :form_name

      def initialize(table, name, options = {})
        super(table, name, options)
        @form_name = options.delete(:form_name)
      end

      def header_code
        "#{@table.model.name}.human_attribute_name('#{@name}')"
      end
    end

  end

end
