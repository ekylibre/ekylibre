# -*- coding: utf-8 -*-
# Adds new renderers for the internal template system
module Ekylibre
  def self.reporting_formats
    return [:pdf, :odt, :ods, :csv, :docx, :xlsx]
  end
end

# Adds renderers for all formats
for format in Ekylibre.reporting_formats
  ActionController::Renderers.add(format) do |object, options|
    # Find template
    name = options[:with]
    unless template = DocumentTemplate.where(:active => true)
        .where(name.is_a?(Integer) ? {:id => name.to_i} : {:by_default => true, :nature => name.to_s})
        .first
      raise StandardError.new("Could not find template for #{name.inspect}")
    end
    self.headers['Cache-Control'] = 'maxage=0'
    self.headers['Pragma'] = 'no-cache'

    options[:filename] ||= "#{controller.human_action_name}.#{format}"

    # Get document data
    data = template.print(object, format, options)

    # Send data
    send_data(data, :filename => options[:filename], :type => format, :disposition => "inline")
  end
end

class ActionController::Responder

  # Adds responders to catch default view rendering and call the previous renderers
  for format in Ekylibre.reporting_formats
    code  = "def to_#{format}\n"
    code << "  controller.render(options.merge(:#{format} => resource))\n"
    code << "end\n"
    eval(code)
  end

end
