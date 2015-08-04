# Adds new renderers for the internal template system
# Adds renderers for all formats
for format in Ekylibre::Reporting.formats
  code  = "ActionController::Renderers.add(:#{format}) do |object, options|\n"
  # Find template
  code << "  name = options[:with]\n"
  code << "  unless template = DocumentTemplate.where(active: true)\n"
  code << "      .where(name.is_a?(Integer) ? {id: name.to_i} : {by_default: true, nature: name.to_s})\n"
  code << "      .first\n"
  code << "    raise StandardError.new(\"Can not find template for \#{name.inspect}\")\n"
  code << "  end\n"
  code << "  if ENV['IN_PASSENGER'] == '1'\n"
  code << "    logger.warn 'Using Jasper/Rjb with Passenger is not sure for now. Be careful.'\n"
  # code << "    logger.warn 'notifications.messages.printing_does_not_work_under_passenger_for_now'.l\n"
  # code << "    return false\n"
  code << "  end\n"
  code << "  self.headers['Cache-Control'] = 'maxage=0'\n"
  code << "  self.headers['Pragma'] = 'no-cache'\n"
  code << "  filename = options.delete(:filename) || (options[:name] ? (options[:name] + '.#{format}') : 'report.#{format}')\n"
  code << "  key = options.delete(:key)\n"
  # Export & send file
  code << "  path = template.export(object.to_xml(options), key, :#{format}, options)\n"
  code << "  send_file(path, filename: filename, type: Mime::#{format.to_s.upcase}, disposition: 'inline')\n"
  code << "end\n"
  eval(code)
end

class ActionController::Responder
  # Adds responders to catch default view rendering and call the previous renderers
  for format in Ekylibre::Reporting.formats
    code  = "def to_#{format}\n"
    code << "  controller.render(options.merge(#{format}: resource))\n"
    code << "end\n"
    eval(code)
  end
end
