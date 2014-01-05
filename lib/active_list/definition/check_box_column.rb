module ActiveList

  module Definition

    class CheckBoxColumn < FieldColumn
      attr_reader :form_value

      def initialize(table, name, options = {})
        super(table, name, options)
        @form_value = options.delete(:form_value)
      end

    end

  end

end
