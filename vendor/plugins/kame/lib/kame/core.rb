# Kame plugin

module Kame
  
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
require "core/definition"
# require "core/columns"
require "core/generator"

# Integration in Rails
require "core/action_pack"
ActionController::Base.send(:include, Kame::ActionController)
ActionView::Base.send(:include, Kame::ActionView)


