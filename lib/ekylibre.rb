module Ekylibre
  autoload :Access,    'ekylibre/access'
  autoload :Export,    'ekylibre/export'
  autoload :FirstRun,  'ekylibre/first_run'
  autoload :Modules,   'ekylibre/modules'
  autoload :Record,    'ekylibre/record'
  autoload :Reporting, 'ekylibre/reporting'
  autoload :Schema,    'ekylibre/schema'
  autoload :Support,   'ekylibre/support'
  autoload :VERSION,   'ekylibre/version'

  def self.migrating?
    return !!(File.basename($0) == "rake" && ARGV.include?("db:migrate"))
  end

  CSV = ::CSV.freeze

  HTTP_LANGUAGES = ::I18n.available_locales.inject({}) do |h, l|
    h["i18n.iso2".t(locale: l)] = l
    h
  end.freeze

  # Returns Ekylibre VERSION
  @@version = nil
  def self.version
    return @@version ||= File.read(Rails.root.join("VERSION"))
  end

  # Must return a File/Dir and not a string
  def self.private_directory
    Rails.root.join("private")
  end

  # Returns all helps files indexed by locale and controller-action
  @@helps = nil
  def self.helps
    return @@helps unless @@helps.nil?
    @@helps = HashWithIndifferentAccess.new
    for locale in ::I18n.available_locales
      @@helps[locale] = HashWithIndifferentAccess.new
      locales_dir = Rails.root.join("config", "locales", locale.to_s, "help")
      for file in Dir[locales_dir.join("**", "*.txt")].sort
        path = Pathname.new(file).relative_path_from(locales_dir)
        File.open(file, 'rb:UTF-8') do |f|
          help = {:title => f.read[/^======\s*(.*)\s*======$/, 1].strip, :name => path.to_s.gsub(/\.txt$/, ''), :file => file}
          unless help[:title].blank?
            @@helps[locale][path.to_s.gsub(/\.txt$/, '')] = help
          end
        end
      end
    end
    return @@helps
  end

end
