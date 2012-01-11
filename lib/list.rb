# List is a plugin for HTML/AJAX table
require 'csv'

module List #:nodoc:
  VERSION = "0.0.1"

  CSV = (::CSV.const_defined?(:Reader) ? ::FasterCSV : ::CSV).freeze

  # class << self
  #   def controller_method_name(name)
  #     "list_#{name}"
  #   end
    
  #   def view_method_name(name)
  #     "list_#{name}_tag"
  #   end

  #   def records_variable_name(name)
  #     "@#{name}"
  #   end
  # end
end

# raise "Stop"

require "list/definition"
require "list/generator"
# Integration in Rails
require "list/action_pack" if defined? Rails
