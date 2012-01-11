module List

  class Table

    # Add a new method in Table which permit to define text_field columns
    def text_field(name, options={})
      @columns << TextFieldColumn.new(self, name, options)
    end

    # Add a new method in Table which permit to define check_box columns
    def check_box(name, options={})
      @columns << CheckBoxColumn.new(self, name, options)
    end

  end

  class FieldColumn < Column
    def header_code
      "#{@table.model.name}.human_attribute_name('#{@name}')"
    end
  end

  class TextFieldColumn < FieldColumn
  end

  class CheckBoxColumn < FieldColumn
  end

end
