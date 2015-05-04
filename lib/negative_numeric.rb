class NegativeNumeric < Numeric

  class << self

    # Convert DB format (string) to SymbolArray
    def load(string)
      return (string.nil? ? 0.0 : string.to_d * -1)
    end

    # Convert SymbolArray to DB format (string)
    def dump(numeric)
      return (-1 * numeric.to_d)
    end

  end

end
