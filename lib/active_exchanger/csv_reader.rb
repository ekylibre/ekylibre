module ActiveExchanger
  class CsvReader
    require 'csv'

    def initialize(col_sep: ',')
      @separator = col_sep
    end

    def read(filename)
      source = File.read(filename)
      detection = CharlockHolmes::EncodingDetector.detect(source)

      CSV.read(filename, headers: true, encoding: detection[:encoding], col_sep: @separator)
    end
  end
end
