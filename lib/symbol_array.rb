class SymbolArray < Array
  class << self
    # Convert DB format (string) to SymbolArray
    def load(string)
      string.to_s.strip.split(/[[:space:]]*\,[[:space:]]*/).map(&:to_sym)
    end

    # Convert SymbolArray to DB format (string)
    def dump(array)
      [array].flatten.map(&:to_s).sort.join(', ')
    end
  end
end
