# List is a plugin for HTML/AJAX table

module List #:nodoc:
  VERSION = "0.0.1"

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
