# = Reload language files
# 
# Reloads all language files of the Simple Localization plugin on each request.
# This is very useful for the development environment. To increase performance
# this feature should not be used in test or production environment.
# 
# == Used sections of the language file
# 
# This feature does not use sections from the lanuage file.

module ArkanisDevelopment::SimpleLocalization #:nodoc:
  module ReloadLangFile
    
    def self.included(target)
      target.class_eval do
        
        before_filter :reload_language
        
        private
        
        def reload_language
          ArkanisDevelopment::SimpleLocalization::Language.reload
        end
        
      end
    end
    
  end
end

ActionController::Base.send :include, ArkanisDevelopment::SimpleLocalization::ReloadLangFile
