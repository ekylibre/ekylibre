# = Localized application
# 
# This feature allows you to use the language file to localize your application.
# You can add your own translation strings to the +app+ section of the language
# file and read them with the +l+ global method. You can use this method in your
# controllers, views, mail templates, simply everywhere. To make the access more
# convenient you can use the +lc+ method in controllers, views, partials,
# models and observers.
# 
#   app:
#     title: Simple Localization Rails plugin
#     subtitle: The plugin should make it much easier to localize Ruby on Rails
#     headings:
#       wellcome: Wellcome to the RDoc Documentation of this plugin
# 
#   l(:title) # => "Simple Localization Rails plugin"
#   l(:headings, :wellcome) # => "Wellcome to the RDoc Documentation of this plugin"
# 
# The +l+ method is just like the 
# ArkanisDevelopment::SimpleLocalization::Language#entry method but is limited
# to the +app+ section of the language file.
# 
# To save some work you can narrow down the scope of the +l+ method even
# further by using the +l_scope+ method:
# 
#   app:
#     layout:
#       nav:
#         main:
#           home: Homepage
#           contact: Contact
#           login: Login
# 
#   l :layout, :nav, :main, :home     # => "Homepage"
#   l :layout, :nav, :main, :contact  # => "Contact"
# 
# Same as
# 
#   l_scope :layout, :nav, :main do
#     l :home     # => "Homepage"
#     l :contact  # => "Contact"
#   end
# 
# Please also take a look at the <code>ContextSensetiveHelpers::lc</code>
# method. It can make life much more easier.
# 
# == Used sections of the language file
# 
# This feature uses the +app+ section of the language file. This section is
# reserved for localizing your application and you can create entries in
# this section just as you need it.
# 
#   app:
#     index:
#       title: Wellcome to XYZ
#       subtitle: Have a nice day...
#     projects:
#       title: My Projects
#       subtitle: This is a list of projects I'm currently working on
# 
#   l(:index, :title) # => "Wellcome to XYZ"
#   l(:projects, :subtitle) # => "This is a list of projects I'm currently working on"
# 

module ArkanisDevelopment::SimpleLocalization #:nodoc:
  module LocalizedApplication #:nodoc:
    
    # This module will extend the ArkanisDevelopment::SimpleLocalization::Language
    # class with all necessary class methods.
    module Language
      
      # Class variable to hold the scope stack of the +app_with_scope+ method.
      @@app_scope_stack = []
      
      # Basically the same as the +app_not_scoped+ method but +app_scoped+ does
      # respect the scope set by the +app_with_scope+ method.
      # 
      # Assuming the following language file data:
      # 
      #   app_default_value: No translation available
      #   app:
      #     index:
      #       title: Welcome to XYZ
      #       subtitle: Have a nice day...
      # 
      # The following code would output:
      # 
      #   Language.app_with_scope :index do
      #     Language.app_scoped :title            # => "Welcome to XYZ"
      #     Language.app_scoped :subtitle         # => "Have a nice day..."
      #     Language.app_scoped "I don't exist"   # => "I don't exist"
      #   end
      #   
      #   Language.app_scoped :index, :title    # => "Welcome to XYZ"
      #   Language.app_scoped :not_existing_key # => "No translation available"
      # 
      def app_scoped(*keys)
        self.app_not_scoped(*(@@app_scope_stack.flatten + keys))
      end
      
      # This class method is used to access entries used by the localized
      # application feature. Since the +app+ section of the language file is
      # reserved for this feature this method restricts the scope of the entries
      # available to the +app+ section. The method should only be used for
      # application localization and therefor there is no need to access other
      # sections of the language file with this method.
      # 
      #   app_default_value: No translation available
      #   app:
      #     index:
      #       title: Welcome to XYZ
      #       subtitle: Have a nice day...
      # 
      #   Language.app_not_scoped(:index, :subtitle) # => "Have a nice day..."
      # 
      # If the specified entry does not exists a default value is returned. If
      # the last argument specified is a string this string is returned as
      # default value. Assume the same language file data as above:
      # 
      #   Language.app_not_scoped(:index, "Welcome to my app") # => "Welcome to my app"
      # 
      # The <code>"Welcome to my app"</code> entry doesn't exists in the
      # language file. Because the last argument is a string it will returned as
      # a default value. If the last argument isn't a string the method will
      # return the +app_default_value+ entry of the language file. Again, same
      # language file data as above:
      # 
      #   Language.app_not_scoped(:index, :welcome) # => "No translation available"
      # 
      # The <code>:welcome</code> entry does not exists. The last argument isn't
      # a string and therefore the value of the +app_default_value+ entry is
      # returned. If this fall back entry does not exists +nil+ is returned.
      # 
      # This method does not respect the scope set by the +with_app_scope+
      # method. This is done by the +app_scoped+ method.
      def app_not_scoped(*keys)
        self.entry(:app, *keys) || begin
          substitution_args = if keys.last.kind_of?(Array)
            keys.pop
          elsif keys.last.kind_of?(Hash)
            [keys.pop]
          else
            []
          end
          if keys.last.kind_of?(String)
            self.substitute_entry keys.last, *substitution_args
          else
            self.entry(:app_default_value)
          end
        end
      end
      
      # Narrows down the scope of the +app_scoped+ method. Useful if you have a
      # very nested language file and don't want to use the +lc+ helpers:
      # 
      #   app:
      #     layout:
      #       nav:
      #         main:
      #           home: Homepage
      #           contact: Contact
      #           about: About
      # 
      # Usually the calls to the +app_scoped+ method would look like this:
      # 
      #   Language.app_scoped :layout, :nav, :main, :home     # => "Homepage"
      #   Language.app_scoped :layout, :nav, :main, :contact  # => "Contact"
      #   Language.app_scoped :layout, :nav, :main, :about    # => "About"
      # 
      # In this situation you can use +with_app_scope+ to save some work:
      # 
      #   Language.with_app_scope :layout, :nav, :main do
      #     Language.app_scoped :home     # => "Homepage"
      #     Language.app_scoped :contact  # => "Contact"
      #     Language.app_scoped :about    # => "About"
      #   end
      # 
      # Every call to the +app_scoped+ method inside the block will
      # automatically be prefixed with the sections you specified to the
      # +with_app_scope+ method.
      def with_app_scope(*scope_sections, &block)
        @@app_scope_stack.push scope_sections
        begin
          yield
        ensure
          @@app_scope_stack.pop
        end
      end
      
      # Added aliases for backward compatibility (pre 2.4 versions).
      alias_method :app, :app_scoped
      alias_method :app_with_scope, :with_app_scope
      
      # A shortcut for creating a CachedLangSectionProxy object. Such a proxy
      # is a object which redirects almost all messages to a specific entry of
      # the currently selected language.
      # 
      # Assume German and English language files like this:
      # 
      # de.yml
      # 
      #   app:
      #     title: Deutscher Test
      #     options: [dies, das, jenes]
      # 
      # en.yml
      # 
      #   app:
      #     title: English test
      #     options: [this, that, other stuff]
      # 
      # Now we can create a proxy object for these entries and switch between
      # languages:
      # 
      #   @title = Language.app_proxy :title
      #   @options = Language.app_proxy :options, :orginal_receiver => []
      #   
      #   # no language file loaded (this is what the <code>orginal_receiver</code> option is for, defaults to "")
      #   @title.inspect  # => ""
      #   @options.inspect  # => []
      #   
      #   # now with switching
      #   Language.use :de
      #   @title.inspect  # => "Deutscher Test"
      #   @options.inspect  # => ["dies", "das", "jenes"]
      #   
      #   Language.use :en
      #   @title.inspect  # => "English test"
      #   @options.inspect  # => ["this", "that", "other stuff"]
      # 
      # This all happens without changing the actual <code>@title</code> or
      # <code>@options</code> variable. So to speek a proxy fakes a simple
      # variable but it's value is exchanged dependend on the current language.
      # 
      # This is actually very useful if a method expects just one variable at
      # the application startup and thus doesn't support language switching,
      # e.g. the message parameter of the +validates_presence_of+ method (here
      # the global +l_proxy+ shortcut for <code>Language.app_proxy</code> is
      # used):
      # 
      #   class Something < ActiveRecord::Base
      #     
      #     validates_presence_of :name, :message => l_proxy(:messages, :name_required)
      #     
      #   end
      # 
      # Now the error message added by +validates_presence_of+ will also be
      # switched if the language is switched. This is a very efficient way to
      # inject language switching code into methods not made for language
      # switching and is used by many other features of this plugin.
      def app_proxy(*keys)
        options = {:orginal_receiver => ''}
        options.update(keys.pop) if keys.last.kind_of?(Hash)
        options[:sections] = [:app] + keys
        CachedLangSectionProxy.new options
      end
      
    end
    
    # This module defines global helper methods and therefor will be
    # included into the Object class.
    module GlobalHelpers
      
      # Defines a global shortcut for the Language#app_scoped method.
      def l(*sections)
        ArkanisDevelopment::SimpleLocalization::Language.app_scoped(*sections)
      end
      
      # The global shortcut for the Language#with_app_scope method.
      def l_scope(*sections, &block)
        ArkanisDevelopment::SimpleLocalization::Language.with_app_scope(*sections, &block)
      end
      
      # A global shortcut for the Language#app_proxy method.
      def l_proxy(*sections)
        ArkanisDevelopment::SimpleLocalization::Language.app_proxy(*sections)
      end
      
    end
    
    module ContextSensetiveHelpers
      
      # This helper provides a short way to access nested language entries by
      # automatically adding a scope to the specified keys. This scope depends
      # on where you call this helper from. If called in the
      # +users_controller.rb+ file it will add <code>:users</code> to it.
      # 
      # This is done by analysing the call stack of the method and there are a
      # few more possibilities:
      # 
      # in <code>app/controllers/users_controller.rb</code>
      # 
      #   lc(:test)  # => will be the same as l(:users, :test)
      # 
      # in <code>app/controllers/projects/tickets_controller.rb</code>
      # 
      #   lc(:test)  # => will be the same as l(:projects, :tickets, :test)
      # 
      # in <code>app/views/users/show.rhtml</code>
      # 
      #   lc(:test)  # => will be the same as l(:users, :show, :test)
      # 
      # in <code>app/views/users/_summary.rhtml</code>
      # 
      #   lc(:test)  # => will be the same as l(:users, :summary, :test)
      # 
      # in <code>app/models/user.rb</code>
      # 
      #   lc(:test)  # => will be the same as l(:user, :test)
      # 
      # in <code>app/models/user_observer.rb</code>
      # 
      #   lc(:test)  # => will be the same as l(:user, :test)
      # 
      def lc(*args)
        args.unshift *get_scope_of_context
        ArkanisDevelopment::SimpleLocalization::Language.app_not_scoped *args
      end
      
      # A context sensetive shortcut for the Language#app_proxy method.
      def lc_proxy(*args)
        args.unshift *get_scope_of_context
        ArkanisDevelopment::SimpleLocalization::Language.app_proxy(*args)
      end
      
      private
      
      # Analyses the call stack to find the rails application file (files in the
      # +app+ directory of the rails application) the context sensitive helper
      # is called in.
      # 
      # You can inject a faked call stack by using the $lc_test_get_scope_of_context_stack
      # global variable. The method will then use this instead of the real call
      # stack. This is handy for testing.
      def get_scope_of_context
        stack_to_analyse = $lc_test_get_scope_of_context_stack || caller
        app_dirs = '(helpers|controllers|views|models)'
        latest_app_file = stack_to_analyse.detect { |level| level =~ /.*\/app\/#{app_dirs}\// }
        return [] unless latest_app_file
        
        path = latest_app_file.match(/([^:]+):\d+.*/)[1]
        dir, file = path.match(/.*\/app\/#{app_dirs}\/(.+)#{Regexp.escape(File.extname(path))}$/)[1, 2]
        
        scope = file.split('/')
        case dir
        when 'controllers'
          scope.last.gsub! /_controller$/, ''
        when 'helpers'
          scope.last.gsub! /_helper$/, ''
        when 'views'
          scope.last.gsub! /^_/, ''
        when 'models'
          scope.last.gsub! /_observer$/, ''
        end
        
        scope
      end
      
    end
    
  end
end

ArkanisDevelopment::SimpleLocalization::Language.send :extend, ArkanisDevelopment::SimpleLocalization::LocalizedApplication::Language

Object.send :include, ArkanisDevelopment::SimpleLocalization::LocalizedApplication::GlobalHelpers
ActionController::Base.send :extend, ArkanisDevelopment::SimpleLocalization::LocalizedApplication::ContextSensetiveHelpers
ActionController::Base.send :include, ArkanisDevelopment::SimpleLocalization::LocalizedApplication::ContextSensetiveHelpers
ActiveRecord::Base.send :extend, ArkanisDevelopment::SimpleLocalization::LocalizedApplication::ContextSensetiveHelpers
ActiveRecord::Base.send :include, ArkanisDevelopment::SimpleLocalization::LocalizedApplication::ContextSensetiveHelpers
ActionView::Base.send :include, ArkanisDevelopment::SimpleLocalization::LocalizedApplication::ContextSensetiveHelpers
