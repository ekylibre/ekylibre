module ActiveList

  module Definition

    class FieldColumn < AbstractColumn
      def header_code
        "#{@table.model.name}.human_attribute_name('#{@name}')"
      end
    end

  end

end
