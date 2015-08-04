class NegativeNumeric < Numeric
  class << self
    # Convert DB format (string) to SymbolArray
    def load(string)
      (string.nil? ? 0.0 : string.to_d * -1)
    end

    # Convert SymbolArray to DB format (string)
    def dump(numeric)
      (-1 * numeric.to_d)
    end
  end
end
