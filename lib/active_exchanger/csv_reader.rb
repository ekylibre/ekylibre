module ActiveExchanger
  class CsvReader
    require 'csv'

    def read(filename)
      source = File.read(filename)
      detection = CharlockHolmes::EncodingDetector.detect(source)

      CSV.read(filename, headers: true, encoding: detection[:encoding], col_sep: ';')
    end
  end
end
