# Kame is a plugin for HTML/AJAX table

module Kame #:nodoc:
  VERSION = "0.0.1"

  class << self
    def controller_method_name(name)
      "#{name}_kame"
    end
    
    def view_method_name(name)
      "#{name}_kame_tag"
    end

    def records_variable_name(name)
      "@#{name}"
    end
  end
end

require "kame/definition"
require "kame/generator"
# Integration in Rails
require "kame/action_pack" if defined? Rails


