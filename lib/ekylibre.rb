module Ekylibre
  autoload :Access,            'ekylibre/access'
  autoload :CorporateIdentity, 'ekylibre/corporate_identity'
  autoload :Export,            'ekylibre/export'
  autoload :FirstRun,          'ekylibre/first_run'
  autoload :Modules,           'ekylibre/modules'
  autoload :Record,            'ekylibre/record'
  autoload :Reporting,         'ekylibre/reporting'
  autoload :Plugin,            'ekylibre/plugin'
  autoload :Schema,            'ekylibre/schema'
  autoload :Snippet,           'ekylibre/snippet'
  autoload :Support,           'ekylibre/support'
  autoload :Tenant,            'ekylibre/tenant'
  autoload :VERSION,           'ekylibre/version'

  CSV = ::CSV.freeze

  HTTP_LANGUAGES = ::I18n.available_locales.inject({}) do |h, l|
    h["i18n.iso2".t(locale: l)] = l
    h
  end.freeze

  class << self

    # Return root path of Ekylibre
    def root
      Rails.root
    end

    # Returns Ekylibre Version
    def version
      Ekylibre::VERSION
    end

    # Returns all helps files indexed by locale and controller-action
    @helps = nil
    def helps
      return @helps unless @helps.nil?
      @helps = HashWithIndifferentAccess.new
      for locale in ::I18n.available_locales
        @helps[locale] = HashWithIndifferentAccess.new
        locales_dir = root.join("config", "locales", locale.to_s, "help")
        for file in Dir[locales_dir.join("**", "*.txt")].sort
          path = Pathname.new(file).relative_path_from(locales_dir)
          File.open(file, 'rb:UTF-8') do |f|
            help = {title: f.read[/^======\s*(.*)\s*======$/, 1].strip, name: path.to_s.gsub(/\.txt$/, ''), file: file}
            unless help[:title].blank?
              @helps[locale][path.to_s.gsub(/\.txt$/, '')] = help
            end
          end
        end
      end
      return @helps
    end

  end

end
