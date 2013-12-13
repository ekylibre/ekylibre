module Ekylibre
  autoload :Schema,    'ekylibre/schema'
  autoload :Record,    'ekylibre/record'
  autoload :Export,    'ekylibre/export'
  autoload :FirstRun,  'ekylibre/first_run'
  autoload :Modules,   'ekylibre/modules'
  autoload :Backup,    'ekylibre/backup'
  autoload :Reporting, 'ekylibre/reporting'

  def self.migrating?
    return !!(File.basename($0) == "rake" && ARGV.include?("db:migrate"))
  end

  CSV = ::CSV.freeze

  @@version = nil

  # Returns Ekylibre VERSION
  def self.version
    return @@version ||= File.read(Rails.root.join("VERSION"))
  end

  # Must return a File/Dir and not a string
  def self.private_directory
    Rails.root.join("private")
  end

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
    # for file in Dir[locales_dir.join("*", "help", "**", "*.txt")].sort
    #   path = Pathname.new(file).relative_path_from(locales_dir)
    #   File.open(file, 'rb:UTF-8') do |f|
    #     help = {:title => f.read[/^======\s*(.*)\s*======$/, 1], :name => file.split(/[\\\/\.]+/)[-2], :locale => file.split(/[\\\/\.]+/)[-4].to_sym}
    #     unless help[:title].blank?
    #       @@helps[file] = help
    #     end
    #   end
    # end
    return @@helps
  end

end
