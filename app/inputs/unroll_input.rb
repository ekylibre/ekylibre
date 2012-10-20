class UnrollInput < SimpleForm::Inputs::Base
  enable :placeholder, :maxlength

  def input
    add_size!
    @builder.text_field(attribute_name, input_html_options)
  end

end
