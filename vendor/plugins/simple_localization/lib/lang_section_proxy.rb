require File.dirname(__FILE__) + '/language'

module ArkanisDevelopment #:nodoc:
  module SimpleLocalization #:nodoc:
    
    # This little thing is a big part of the magic of doing things behind Rails
    # back. Basically it mimics an variable (ie. number, array, hash, ...) by
    # redirecting all calls to another variable of that kind. The target object
    # will be accessed by the Language#[] accessor and therefore will always
    # return the data for the currently selcted language without replacing the
    # proxy object.
    # 
    # This is useful if Rails stors the target data only in a constant. With
    # this proxy the constant can be replaced once (with a proxy) and will
    # always return the language data of the currently selected language.
    class LangSectionProxy
      
      # Stripped out of Rails AssociationProxy class to undefine many of the
      # methods that come with new objects...
      instance_methods.each { |m| undef_method m unless m =~ /(^__|^nil\?$|^send$)/ }
      
      # Reads the specified options and the accociated block and save them to
      # instance variables.
      # 
      # Available options are:
      # 
      # <code>:sections</code>
      #   Specifies the sections of the language file which contain the
      #   receiver. These sections will be used as parameters to the
      #   Language#[] method to actually get the receiver.
      # <code>:orginal_receiver</code>
      #   Specify the original variable that is replaced by this proxy to store
      #   this variable inside the proxy. This is useful if you want to combine
      #   the language data with the original data. The variable specified here
      #   is accessable as the second variable of the attached block.
      # <code>:lang_class</code>
      #   The class supplying the proxy with language data. Defaults to
      #   <code>ArkanisDevelopment::SimpleLocalization::Language</code>. You
      #   can for example write a mock class implementing the [] class method
      #   use and this option to make the proxy use this mock class.
      #   
      #     class LangMock
      #       def self.[](*sections)
      #         {:title => 'test data'}
      #       end
      #     end
      #     
      #     LangSectionProxy.new :lang_class => LangMock
      # 
      # If you want to combine the original data (supplied to the
      # <code>:orginal_receiver</code> option) with the localized data in some
      # way (ie. merging the old data with the localized data) you can specify
      # a block. The block takes the localized data as the first parameter, the
      # original data as the second parameter and should return the combined
      # result.
      # 
      #   data = {:a => 'first', :b => 'second', :c => 'third'}
      #   LangSectionProxy.new :sections => [:letter_to_word, :mapping], :original_data => data do |localized, original|
      #     original.merge localized
      #   end
      # 
      def initialize(options, &transformation)
        default_options = {:sections => nil, :orginal_receiver => nil, :lang_class => ArkanisDevelopment::SimpleLocalization::Language}
        options.reverse_merge! default_options
        options.assert_valid_keys default_options.keys
        
        @sections = options[:sections]
        @orginal_receiver = options[:orginal_receiver]
        @lang_class = options[:lang_class]
        @transformation = transformation
      end
      
      # Gets the receiver from the language class and combines this data with
      # the original data if wanted (a block was specified to the constructor).
      # If the lang class isn't loaded yet only the original data will be
      # returned as a fallback value.
      def receiver
        if @lang_class.loaded?
          receiver = @lang_class.entry(*@sections)
          if @transformation.respond_to?(:call)
            receiver = @transformation.arity == 1 ? @transformation.call(receiver) : @transformation.call(receiver, @orginal_receiver)
          end
          receiver
        else
          @orginal_receiver
        end
      end
      
      # Intercept all other messages and send them to the receiver.
      def method_missing(name, *args, &block)
        self.receiver.send name, *args, &block
      end
      
    end
    
  end
end
