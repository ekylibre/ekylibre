require File.dirname(__FILE__) + '/lang_file'
require File.dirname(__FILE__) + '/errors'

module ArkanisDevelopment #:nodoc:
  module SimpleLocalization #:nodoc:
    
    # This module loads and manages access to the used language files.  
    module Language
      
      @@languages = {}
      @@current_language = nil
      @@options = {
        :lang_file_dirs => ["#{File.dirname(__FILE__)}/../languages"],
        :debug => false,
      }
      @@loaded_features = []
      
      mattr_accessor :options
      mattr_accessor :loaded_features
      
      class << self
        
        # Define module level accessors for all options in the @@options hash.
        @@options.keys.each do |option|
          class_eval <<-EOM
            def #{option}; options[:#{option}]; end
            def #{option}=(new_value); options[:#{option}] = new_value; end
          EOM
        end
        
        # Returns the name of the currently used language as a symbol.
        # 
        #   Language.current_language = :de
        #   Language.current_language # => :de
        # 
        def current_language
          @@current_language
        end
        
        alias_method :used, :current_language
        
        # Sets the currently used language. If the specified language file
        # is not loaded a +LangFileNotLoaded+ exception will be raised.
        # 
        #   simple_localization :languages => [:de, :en]
        #   Language.current_language # => :de
        #   Language.current_language = :en
        #   Language.current_language # => :en
        # 
        # There are also aliases for the +current_language+ attribute accessor:
        # 
        #   simple_localization :languages => [:de, :en]
        #   Language.used # => :de
        #   Language.use :en
        #   Language.used # => :en
        # 
        def current_language=(new_lang)
          if loaded_languages.include? new_lang.to_sym
            @@current_language = new_lang.to_sym
          else
            raise LangFileNotLoaded.new(new_lang, loaded_languages)
          end
        end
        
        alias_method :use, :current_language=
        
        # Checks if the specified language is loaded or when called without an
        # argument if at least one language is loaded. Handy to check if the
        # plugin is initialized.
        def loaded?(language_name = nil)
          if language_name
            self.loaded_languages.include? language_name
          else
            not self.loaded_languages.blank?
          end
        end
        
        # Returns a hash with all loaded LangFile objects.
        def lang_files
          @@languages
        end
        
        # Returns the language codes of currently loaded languages.
        # 
        #   Language.loaded_languages  # => [:de, :en]
        # 
        def loaded_languages
          @@languages.keys
        end
        
        # Loads the specified language files. If currently no language is
        # selected the first one of the specified files will be selected.
        # 
        # The path to the language files can be specified in the +lang_file_dirs+
        # option.
        # 
        #   Language.load :de, :en
        # 
        # This will load the files <code>de.yml</code> and <code>en.yml</code>
        # and all of it's parts in the language file directory. If existing the
        # files <code>de.rb</code> and <code>en.rb</code> will be executed. It
        # also selects <code>:de</code> as the active language because it was
        # specified first.
        def load(*languages)
          languages.flatten!
          languages.each do |lang_code|
            lang_file = LangFile.new lang_code, self.lang_file_dirs
            @@languages[lang_code.to_sym] = lang_file
            lang_file.load
          end
          self.use languages.first if current_language.nil?
        end
        
        # Reload the data of all loaded language files by calling the
        # LangFile#reload method on each language file.
        def reload
          @@languages.each do |lang_code, lang_file|
            lang_file.reload
          end
        end
        
        # Searches the date of the specified language file for the entry
        # addressed by +keys+.
        # 
        # If the specified language file is not loaded an +LangFileNotLoaded+
        # exception is raised. If the entry is not found an +EntryNotFound+
        # exception is raised.
        # 
        #   Language.find :de, :active_record_messages, :not_a_number  # => "ist keine Zahl."
        # 
        def find(language, *keys)
          language = language.to_sym
          if @@languages.empty? or not @@languages[language]
            raise LangFileNotLoaded.new(language, loaded_languages)
          end
          
          keys.collect!{|key| key.kind_of?(Numeric) ? key : key.to_s}
          begin
            @@languages[language].data[*keys]
          rescue EntryNotFound
            raise EntryNotFound.new(keys, language) # reraise with more details
          end
        end
        
        # Returns the specified entry from the currently used language file.
        # It's possible to specify nested entries by using more than one
        # parameter.
        # 
        #   Language.entry :active_record_messages, :too_short  # => "ist zu kurz (mindestens %d Zeichen)."
        # 
        # This will return the +too_short+ entry within the +active_record_messages+
        # entry. The YAML code in the language file looks like this:
        # 
        #   active_record_messages:
        #     too_short: ist zu kurz (mindestens %d Zeichen).
        # 
        # If the entry is not found +nil+ is returned.
        # 
        # This method also allows you to substitute values inside the found
        # entry. The +substitute_entry+ method is used for this and there are
        # two ways to do this:
        # 
        # With +format+:
        # 
        # Just specify an array with the format values as last key:
        # 
        #   Language.entry :active_record_messages, :too_short, [5] # => "ist zu kurz (mindestens 5 Zeichen)."
        # 
        # If +format+ fails the reaction depends on the +debug+ option of the
        # Language module. If +debug+ is set to +false+ the unformatted entry is
        # returned. If +debug+ is +true+ an +EntryFormatError+ is raised
        # detailing what went wrong.
        # 
        # With "hash notation" like used by the ActiveRecord conditions:
        # 
        # It's also possible to use a hash to specify the values to substitute.
        # This works like the conditions of ActiveRecord:
        # 
        #   app:
        #     welcome: Welcome :name, you have :number new messages.
        # 
        #   Language.entry :app, :welcome, :name => 'Mr. X', :number => 5  # => "Welcome Mr. X, you have 5 new messages."
        # 
        # Both approaches allow you to use the \ character to escape colons (:)
        # and percent sings (%).
        def entry(*args)
          begin
            entry!(*args)
          rescue EntryNotFound
            nil
          end
        end
        
        alias_method :[], :entry
        
        # Same as the +Language#entry+ method but it raises an +EntryNotFound+
        # exception if the specified entry does not exists.
        def entry!(*args)
          substitute_values = if args.last.kind_of?(Hash)
            [args.delete_at(-1)]
          elsif args.last.kind_of?(Array)
            args.delete_at(-1)
          else
            []
          end
          
          entry = self.find(self.current_language, *args)
          entry.kind_of?(String) ? substitute_entry(entry, *substitute_values) : entry
        rescue EntryFormatError => e
          raise EntryFormatError.new(e.language, args, e.entry_content, e.format_values, e.original_exception) # reraise with more details
        end
        
        # Substitutes a string with values by using +format+ or a hash like
        # known from the ActiveRecord conditions.
        # 
        #   substitute_entry 'substitute %s and %i', 'this', 10               # => "substitute this and 10"
        #   substitute_entry 'escape %%s but not %s', 'this'                  # => "escape %s but not this"
        #   substitute_entry 'substitute :a and :b', :a => 'this', :b => 10   # => "substitute this and 10"
        #   substitute_entry 'escape \:a but not :b', :b => 'this'            # => "escape :a but not this"
        # 
        # If the format style is used and an error occurs an +EntryFormatError+
        # will be raised. It contains some extra information as well as the
        # original exception.
        def substitute_entry(string, *values)
          return unless string
          if values.last.kind_of?(Hash)
            string = ' ' + string
            values.last.each do |key, value|
              string.gsub!(/([^\\]):#{key}/, "\\1#{value}")
            end
            string.gsub!(/([^\\])\\:/, '\\1:')
            string[1, string.length]
          elsif not values.empty?
            begin
              format(string, *values)
            rescue StandardError => e
              self.debug ? raise(EntryFormatError.new(self.current_language, [], string, values, e)) : string
            end
          else
            string
          end
        end
        
        # Returns a hash with the meta data of the specified language (defaults
        # to the currently used language). Entries not present in the language
        # file will default to +nil+. If the specified language file is not
        # loaded an +LangFileNotLoaded+ exception is raised.
        # 
        #   Language.about :de
        #   # => {
        #          :language => 'Deutsch',
        #          :author => 'Stephan Soller',
        #          :comment => 'Deutsche Sprachdatei. Kann als Basis für neue Sprachdatein dienen.',
        #          :website => 'http://www.arkanis-development.de/',
        #          :email => nil, # happens if no email is specified in the language file.
        #          :date => '2007-01-20'
        #        }
        # 
        def about(lang = self.current_language)
          lang = lang.to_sym
          
          defaults = {
            :language => nil,
            :author => nil,
            :comment => nil,
            :website => nil,
            :email => nil,
            :date => nil
          }
          
          defaults.update self.find(lang, :about).symbolize_keys
        end
        
      end
      
    end
    
  end
end
