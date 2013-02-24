class DateFieldInput < SimpleForm::Inputs::StringInput
  def input_html_options
    value = object.send(attribute_name)
    format = @options[:format] || :default
    raise ArgumentError.new("Option :format must be a Symbol referencing a translation 'date.formats.<format>'") unless format.is_a?(Symbol)
    if localized_value = value
      localized_value = I18n.localize(localized_value, :format => format)
    end
    format = I18n.translate('date.formats.'+format.to_s)
    Formize::DATE_FORMAT_TOKENS.each{|js, rb| format.gsub!(rb, js)}
    options = {
      "data-date" => format,
      "data-date-locale" => "i18n.iso2".t,
      "data-date-iso" => value,
      :value => localized_value,
      :size => @options.delete(:size) || 10
    }
    super.merge options
  end
end
