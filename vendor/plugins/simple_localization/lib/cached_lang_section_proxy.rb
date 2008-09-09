require File.dirname(__FILE__) + '/lang_section_proxy'

module ArkanisDevelopment #:nodoc:
  module SimpleLocalization #:nodoc:
    
    # Extends the LangSectionProxy with simple caching functionality to avoid
    # extensive combination work on every proxy method call.
    class CachedLangSectionProxy < LangSectionProxy
      
      # Calls +super+ to do the work and initializes +@cached_receivers+ with
      # an empty hash (empty cache). +@cached_receivers+ will hold a cached
      # version of the receiver for each language file (keys of the hash).
      def initialize(*args)
        super
        @cached_receivers = {}
      end
      
      # Looks in the +@cached_receivers+ hash for a cached receiver for the
      # current language. If found the cached on will be used. Otherwise
      # +self.receiver+ will be called to get the receiver (and all the
      # combination work is done) and the result is cached in the
      # +@cached_receivers+ hash.
      # 
      # If currently no language is loaded (@lang_class.current_language returns
      # nil) +self.receiver+ is called without being cached. This is because if
      # no language file is loaded +self.receiver+ will probably return a
      # fallback value.
      def method_missing(name, *args, &block)
        lang = @lang_class.current_language
        target_receiver = if lang
          @cached_receivers[lang] || begin
            @cached_receivers[lang] = self.receiver
          end
        else
          self.receiver
        end
        target_receiver.send name, *args, &block
      end
      
    end
    
  end
end
