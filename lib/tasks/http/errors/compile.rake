namespace :http do
  namespace :errors do
    desc 'Compile static error pages for each locale'
    task compile: :environment do
      # Localize static errors files
      errors = {
        not_found: 404,
        unprocessable_entity: 422,
        internal_server_error: 500,
        maintenance: 'maintenance'
      }

      path = Rails.root.join('lib', 'tasks', 'http', 'errors', 'error.haml')
      template = Tilt.new(path.to_s)
      ::I18n.available_locales.delete_if { |l| l.to_s.size != 3 }.each do |locale|
        I18n.locale = locale
        errors.each do |name, code|
          details = I18n.translate("http.errors.#{name}", default: '', fallback: [])
          next if details.blank?
          file_name = "public/#{code}"
          file_name << ".#{locale}" unless I18n.default_locale == locale
          file_name << '.html'
          puts file_name.to_s
          html = template.render(name.to_s.humanize, name: name, code: code).gsub!(/[\ \t]+\n/, "\n")
          File.write(Rails.root.join(file_name), html)
        end
      end
    end
  end
end
