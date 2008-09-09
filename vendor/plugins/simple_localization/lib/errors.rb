module ArkanisDevelopment #:nodoc:
  module SimpleLocalization #:nodoc:
    
    class SimpleLocalizationError < StandardError; end
    
    # Custom error class raised if the uses tries to select a language file
    # which is not loaded. Also stores the name of the failed language file and
    # a list of the loaded ones.
    # 
    #   begin
    #     Language.about :xyz
    #   rescue LangFileNotLoaded => e
    #     e.failed_lang   # => :xyz
    #     e.loaded_langs  # => [:de, :en]
    #   end
    # 
    class LangFileNotLoaded < SimpleLocalizationError
      
      attr_reader :failed_lang, :loaded_langs
      
      def initialize(failed_lang, loaded_langs)
        @failed_lang, @loaded_lang = failed_lang, loaded_langs
        super "The language file \"#{failed_lang}\" is not loaded (currently " +
          "loaded: #{loaded_langs.join(', ')}). Please call the " +
          'simple_localization method at the end of your environment.rb ' +
          'file to initialize Simple Localization or modify this call to ' +
          'include the selected language.'
      end
      
    end
    
    # This error is raised if a requested entry could not be found. This error
    # also stores the requested entry and the language for which the entry
    # could not be found.
    # 
    #   begin
    #     Language.find :en, :nonsens, :void
    #   rescue EntryNotFound => e
    #     e.requested_entry  # => [:nonsens, :void]
    #     e.language         # => :en
    #   end
    # 
    class EntryNotFound < SimpleLocalizationError
      
      attr_reader :requested_entry, :language
      
      def initialize(requested_entry = [], language = nil)
        @requested_entry, @language = Array(requested_entry), language
        super "The requested entry '#{@requested_entry.join('\' -> \'')}' could " +
          "not be found in the language '#{@language}'."
      end
      
    end
    
    # Error raised if the format method for a language file entry fails. The
    # main purpose of this error is to make debuging easier if format fails.
    # Therefore the detailed error message.
    # 
    #   Language.use :en
    #   
    #   begin
    #     Language.entry :active_record_messages, :too_short, ['a']
    #   rescue EntryFormatError => e
    #     e.language            # => :en
    #     e.entry               # => [:active_record_messages, :too_short]
    #     e.entry_content       # => 'is too short (minimum is %d characters)'
    #     e.format_values       # => ['a']
    #     e.original_exception  # => #<ArgumentError: invalid value for Integer: "a">
    #   end
    # 
    class EntryFormatError < SimpleLocalizationError
      
      attr_reader :language, :entry, :entry_content, :format_values, :original_exception
      
      def initialize(language, entry, entry_content, format_values, original_exception)
        @language, @entry, @entry_content, @format_values, @original_exception = language, entry, entry_content, format_values, original_exception
        super "An error occured while formating the language file entry '#{@entry.join('\' -> \'')}'.\n" +
          "Format string: '#{@entry_content}'\n" +
          "Format arguments: #{@format_values.collect{|v| v.inspect}.join(', ')}\n" +
          "Original exception: #{@original_exception.inspect}"
      end
      
    end
    
  end
end
