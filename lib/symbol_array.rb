class SymbolArray < Array

  class << self

    # Convert DB format (string) to SymbolArray
    def load(string)
      return string.to_s.strip.split(/[[:space:]]*\,[[:space:]]*/).map(&:to_sym)
    end

    # Convert SymbolArray to DB format (string)
    def dump(array)
      return [array].flatten.map(&:to_s).sort.join(', ')
    end

  end

end
