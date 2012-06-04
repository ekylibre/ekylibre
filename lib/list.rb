# List is a plugin for HTML/AJAX table
require 'csv'

module List #:nodoc:
  VERSION = "0.0.2"

  CSV = (::CSV.const_defined?(:Reader) ? ::FasterCSV : ::CSV).freeze
end

require "list/definition"
require "list/generator"
# Integration in Rails
require "list/action_pack" if defined? Rails
