module ActiveExchanger
  class CsvReader
    require 'csv'

    # Possible CSV separators to check
    SEPARATORS = [",", ";", "\t", "|", "#"].freeze

    def initialize(col_sep: ',', headers: true)
      @separator = col_sep
      @headers = headers
    end

    def read(filename, col_sep: @separator)
      source = File.read(filename)
      detection = CharlockHolmes::EncodingDetector.detect(source)

      col_sep ||= separator(File.read(filename, encoding: detection[:encoding]))

      CSV.read(filename, headers: @headers, encoding: detection[:encoding], col_sep: col_sep)
    end

    private

      # @param file_or_data [File, String] CSV file or data to probe
      # @return [String] most probable column separator character from first line, or +nil+ when none found
      # @todo return whichever character returns the same number of columns over multiple lines
      def separator(file_or_data)
        if file_or_data.is_a? File
          position = file_or_data.tell
          firstline = file_or_data.readline
          file_or_data.seek(position)
        else
          firstline = file_or_data.split("\n", 2)[0]
        end
        separators = SEPARATORS.map{|s| s.encode(firstline.encoding)}
        sep = separators.map {|x| [firstline.count(x), x]}.max_by {|x| x[0]}
        sep[0] == 0 ? nil : sep[1].encode('ascii')
      end
  end
end
