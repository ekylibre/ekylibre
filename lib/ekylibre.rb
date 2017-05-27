module Ekylibre
  autoload :Access,            'ekylibre/access'
  autoload :CorporateIdentity, 'ekylibre/corporate_identity'
  autoload :Export,            'ekylibre/export'
  autoload :FirstRun,          'ekylibre/first_run'
  autoload :Hook,              'ekylibre/hook'
  autoload :Navigation,        'ekylibre/navigation'
  autoload :Record,            'ekylibre/record'
  autoload :Reporting,         'ekylibre/reporting'
  autoload :Plugin,            'ekylibre/plugin'
  autoload :Schema,            'ekylibre/schema'
  autoload :Secret,            'ekylibre/secret'
  autoload :Snippet,           'ekylibre/snippet'
  autoload :Support,           'ekylibre/support'
  autoload :Tenant,            'ekylibre/tenant'
  autoload :VERSION,           'ekylibre/version'
  autoload :View,              'ekylibre/view'

  CSV = ::CSV.freeze

  class << self
    def http_languages
      ::I18n.available_locales.each_with_object({}) do |l, h|
        h['i18n.iso2'.t(locale: l)] = l
        h
      end
    end

    # Return root path of Ekylibre
    def root
      Rails.root
    end

    # Returns Ekylibre Version
    def version
      Ekylibre::VERSION
    end

    # Returns list of themes
    def themes
      unless @themes
        Dir.chdir(root.join('app', 'themes')) do
          @themes = Dir.glob('*')
        end
      end
      @themes
    end

    def load_integrations
      Dir.glob(Rails.root.join('app', 'integrations', '**', '*.rb')).each do |file|
        require file
      end
      Ekylibre::Plugin.load_integrations
    end

    # Returns all helps files indexed by locale and controller-action
    @helps = nil
    def helps
      return @helps unless @helps.nil?
      @helps = HashWithIndifferentAccess.new
      for locale in ::I18n.available_locales
        @helps[locale] = HashWithIndifferentAccess.new
        locales_dir = root.join('config', 'locales', locale.to_s, 'help')
        for file in Dir[locales_dir.join('**', '*.txt')].sort
          path = Pathname.new(file).relative_path_from(locales_dir)
          File.open(file, 'rb:UTF-8') do |f|
            help = { title: f.read[/^======\s*(.*)\s*======$/, 1].strip, name: path.to_s.gsub(/\.txt$/, ''), file: file }
            if help[:title].present?
              @helps[locale][path.to_s.gsub(/\.txt$/, '')] = help
            end
          end
        end
      end
      @helps
    end
  end
end
