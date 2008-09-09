# = Localized application extensions
# 
# This feature adds the +l+ and +lc+ helper methods to the String and Symbol
# class. This is a common way to localize strings.
# 
# == Used sections of the language file
# 
# This feature uses the +app+ section of the language file. This section is
# reserved for localizing your application and you can create entries in
# this section just as you need it.
# 
#   app:
#     test: this is a test
#     users:
#       show:
#         title: Showing user...
# 
# Somewhere in your app:
# 
#   'test'.l  # => "this is a test"
#   :test.l   # => "this is a test"
# 
# in <code>app/views/users/show.rhtml</code>:
# 
#   :title.lc   # => "Showing user..."
#   'title'.lc  # => "Showing user..."
# 

require File.expand_path(File.dirname(__FILE__) + '/localized_application')

module ArkanisDevelopment::SimpleLocalization #:nodoc:
  module LocalizedApplicationExtensions #:nodoc:
    
    include ArkanisDevelopment::SimpleLocalization::LocalizedApplication::ContextSensetiveHelpers
    
    # A shortcut for the LocalizedApplication::GlobalHelpers#l method. It'll use
    # the value of the string or the name of the symbol as the key to query. Any
    # arguments supplied to this method will be used to format the entry.
    # 
    # Assume the following language file data:
    # 
    #   app:
    #     welcome: Welcome to my page
    #     footer: 'Done by %s'
    #     Welcome to this test page: Willkommen auf dieser Testseite
    #     'This page was created by %s': Diese Seite wurde von %s erstellt
    # 
    # And here's some sample code:
    # 
    #   :welcome.l        # => "Welcome to my page"
    #   :footer.l 'Mr. X' # => "Done by Mr. X"
    #   :unknown.l        # => nil
    # 
    # You can also use this method on strings. However editing the string would
    # result in a new key and therefore a new entry in the language file. Once
    # an entry is created please don't modify the string. Maintenance could
    # become very annoying in this case.
    # 
    # However the value of the string will be used as a default value if the
    # specified entry does not exist. This could come in quite handy sometimes.
    # 
    #   "Welcome to this test page".l           # => "Willkommen auf dieser Testseite"
    #   "This page was created by %s".l 'Mr. X' # => "Diese Seite wurde von Mr. X erstellt"
    #   "This text isn't localized".l           # => "This text isn't localized"
    # 
    def l(*args)
      app_args = [self.to_s]
      if args.first.kind_of?(Hash)
        app_args << args.first
      else
        app_args << args unless args.empty?
      end
      Language.app_scoped *app_args
    end
    
    # Shortcut for the LocalizedApplication::GlobalHelpers#lc method. It'll use
    # the value of the string or the name of the symbol as the key to query. Any
    # arguments supplied to this method will be used to format the entry.
    # 
    # Assume the following language file data:
    # 
    #   app:
    #     users:
    #       title: Benutzer
    #       show:
    #         title: Zeige Benutzer :name
    #         ':post_count posts so far': bisher :post_count Beiträge
    # 
    # And here's some sample code of the file <code>app/users_controller.rb</code>:
    # 
    #   :title.lc  # => "Benutzer"
    # 
    # And now in the view <code>app/views/users/show.rhtml</code>:
    # 
    #   :title.lc :name => 'Mr. X'  # => "Zeige Benutzer Mr. X"
    #   ':post_count posts so far'.lc :post_count => 10  # => "bisher 10 Beiträge"
    # 
    # You can also use this method on strings. However editing the string would
    # result in a new key and therefore a new entry in the language file. Once
    # an entry is created please don't modify the string. Maintenance could
    # become very annoying in this case.
    # 
    # However the value of the string will be used as a default value if the
    # specified entry does not exist. This could come in quite handy sometimes.
    # 
    def lc(*args)
      app_args = get_scope_of_context
      app_args << self.to_s
      if args.first.kind_of?(Hash)
        app_args << args.first
      else
        app_args << args unless args.empty?
      end
      Language.app_not_scoped *app_args
    end
    
  end
end

String.send :include, ArkanisDevelopment::SimpleLocalization::LocalizedApplicationExtensions
Symbol.send :include, ArkanisDevelopment::SimpleLocalization::LocalizedApplicationExtensions
