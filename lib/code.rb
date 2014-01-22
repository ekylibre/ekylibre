# This class permits to manipulate String that is program's code
class Code < String

  class IncompatibleLanguage < StandardError
  end

  @@default_language = :ruby

  cattr_accessor :default_language
  attr_reader :language

  def initialize(text, language = nil)
    @language = language || @@default_language
    super text
  end

  def +(text)
    if text.is_a?(Code)
      if code.language == text.language
        super text
      else
        raise IncompatibleLanguage, "Language #{self.language} is not compatible with language: #{text.language}"
      end
    else
      super text
    end
  end

  def <<(text)
    if text.is_a?(Code)
      if code.language == text.language
        super text
      else
        raise IncompatibleLanguage, "Language #{self.language} is not compatible with language: #{text.language}"
      end
    else
      super text.to_s
    end
  end

  def inspect
    self.to_s
  end

end
