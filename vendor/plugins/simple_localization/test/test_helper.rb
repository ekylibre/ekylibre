# Load all necessary libraries, gems and the init script.
require 'test/unit'
require 'logger'
require 'rubygems'
require 'active_support'
require 'active_record'
require 'action_controller'
require 'action_view'

# Set the LANG_FILE constant to the LANG_FILE environment variable. This is the
# name of the language file the tests will use. Defaults to 'de'.
LANG_FILE = ENV['LANG_FILE'] || 'de'
LANG_FILE_DIR = ENV['LANG_FILE_DIR'] || (File.dirname(__FILE__) + '/languages')

# Define a Rails root (just to avoid const undefined errors) and emulate the
# default Rails logger and send it's output to the file test.log.
RAILS_ROOT = './script/../config/..'
RAILS_DEFAULT_LOGGER = Logger.new(File.dirname(__FILE__) + '/test.log')

# Mimic the Rails version interface. This makes it also possible to test
# features for different rails versions.
module Rails
  module VERSION
    MAJOR, MINOR, TINY = (ENV['RAILS'] || '2.0.1').split('.')
  end
end

# Require the plugin after the necessary stuff is setup
require File.dirname(__FILE__) + '/../init'

# Reset the language file directory list to exclude the default language files.
ArkanisDevelopment::SimpleLocalization::Language.lang_file_dirs = []

# Define the +assert_contains+ helper used in some of the test cases.
class Test::Unit::TestCase
  
  protected
  
  def assert_contains(subject, search_string)
    assert subject[search_string], "'#{subject}' should contain '#{search_string}' but doesn't"
  end
  
  def load_language_file_contents(lang_file_dir = LANG_FILE_DIR)
    Dir.glob("#{lang_file_dir}/*.yml").collect{|path| File.basename(path, '.yml')}.inject({}) do |memo, lang_file|
      memo[lang_file] = YAML.load_file "#{LANG_FILE_DIR}/#{lang_file}.yml"
      memo
    end
  end
  
end
