require_relative 'ekylibre/record'
require_relative 'ekylibre/models'
require_relative 'ekylibre/export'
require_relative 'ekylibre/menus'
require_relative 'ekylibre/routes'
require_relative 'ekylibre/backup'
require_relative 'ekylibre/reporting'

require 'csv'

module Ekylibre

  mattr_reader :model_names
  @@model_names = @@models.collect{|m| m.to_s.camelcase.to_sym}.sort.freeze

  def self.migrating?
    return !!(File.basename($0) == "rake" && ARGV.include?("db:migrate"))
  end

  CSV = (::CSV.const_defined?(:Reader) ? ::FasterCSV : ::CSV).freeze

  @@version = nil

  # Return Ekylibre VERSION
  def self.version
    return @@version unless @@version.nil?
    File.open(Rails.root.join("VERSION")) {|f| @@version = f.read.split(',')[0..1].join("::")}
    return @@version
  end

  # Must return a File/Dir and not a string
  def self.private_directory
    Rails.root.join("private")
  end

  @@helps = nil

  def self.helps
    return @@helps unless @@helps.nil?
    @@helps = HashWithIndifferentAccess.new
    for locale in ::I18n.active_locales
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
