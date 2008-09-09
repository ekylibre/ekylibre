module LanguageMock
  
  @@data = {}
  @@current_language = :en
  @@loaded = true
  
  mattr_accessor :loaded
  
  class << self
    
    def data
      @@data
    end
    
    def data=(new_data)
      @@data = new_data
    end
    
    def current_language
      @@current_language
    end
    
    def current_language=(new_lang)
      @@current_language = new_lang
    end
    
    alias_method :used, :current_language
    alias_method :use, :current_language=
    
    def entry(*args)
      @@data[@@current_language]
    end
    
    def current_lang_data
      @@data[@@current_language]
    end
    
    def current_lang_data=(new_data)
      @@data[@@current_language] = new_data
    end
    
    def loaded?
      @@loaded
    end
    
  end
  
end
