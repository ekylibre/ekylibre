require File.join(File.dirname(__FILE__), 'safe_string')
# require File.join(File.dirname(__FILE__), 'i18n')
# require File.join(File.dirname(__FILE__), 'spreet')
require File.join(File.dirname(__FILE__), 'activerecord')
require File.join(File.dirname(__FILE__), 'ekylibre')

module Ekylibre
  @@version = nil
  
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
    @@helps ||= {}
    for file in Dir[Rails.root.join("config", "locales", "*", "help", "*.txt")].sort
      File.open(file, 'rb') do |f| 
        @@helps[file] = {:title=>f.read[/^======\s*(.*)\s*======$/, 1], :name=>file.split(/[\\\/\.]+/)[-2], :locale=>file.split(/[\\\/\.]+/)[-4].to_sym}
        raise Exception.new("No valid title for #{file}") if @@helps[file][:title].blank?
      end
    end
    return @@helps
  end

end
