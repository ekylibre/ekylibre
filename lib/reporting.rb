# Adds new renderers for the internal template system
# Adds renderers for all formats
Ekylibre::Reporting.formats.each do |format|
  ActionController::Renderers.add(format) do |object, options| # Find template
    name = options[:with]
    unless template = DocumentTemplate.find_active_template(name)
      raise StandardError, "Can not find template for \#{name.inspect}"
    end
    if ENV['IN_PASSENGER'] == '1'
      logger.warn 'Using Jasper/Rjb with Passenger is not sure for now. Be careful.'
      #     logger.warn 'notifications.messages.printing_does_not_work_under_passenger_for_now'.l
      #     return false
    end
    headers['Cache-Control'] = 'maxage=0'
    headers['Pragma'] = 'no-cache'
    filename = options.delete(:filename) || (options[:name] ? (options[:name] + ".#{format}") : "report.#{format}")
    key = options.delete(:key)
    # Export & send file
    path = template.export(object.to_xml(options), key, format, options)
    send_file(path, filename: filename, type: Mime.const_get(format.to_s.upcase), disposition: 'inline')
  end
end

module ActionController
  class Responder
    # Adds responders to catch default view rendering and call the previous renderers
    Ekylibre::Reporting.formats.each do |format|
      define_method :"to_#{format}" do
        controller.render(options.merge("#{format}": resource))
      end
    end
  end
end
