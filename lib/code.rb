class IncompatibleLanguage < StandardError
end

# This class permits to manipulate String that is program's code
class Code < String

  attr_reader :language

  def initialize(text, language = :ruby)
    @language = language
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

class ::String
  # Convert a String to a Code fragment
  def to_code(language = nil)
    Code.new(self, language)
  end

  def c(language = nil)
    Code.new(self, language)
  end
end
