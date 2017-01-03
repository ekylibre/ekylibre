class FinancialYearExchangeExport
  class InvalidFormatError < StandardError; end

  def initialize(exchange)
    @exchange = exchange
  end

  def export(format)
    build_export(format) do |file, name|
      zip_filename = "#{name}.zip"
      zip_file(zip_filename, name, file.path) do |zip|
        yield zip, zip_filename
      end
    end
  end

  private

  attr_reader :exchange

  def build_export(format, &block)
    if format == 'csv'
      CsvExport.new(exchange).export(&block)
    else
      raise InvalidFormatError, "Format '#{format}' is not supported"
    end
  end

  def zip_file(zip_filename, filename, filepath)
    tempfile = build_zip_tempfile(zip_filename)
    Zip::File.open(tempfile.path, Zip::File::CREATE) do |z|
      z.add filename, filepath
    end
    yield tempfile
  ensure
    tempfile.close!
  end

  def build_zip_tempfile(filename)
    tempfile = Tempfile.new(filename)
    Zip::OutputStream.open(tempfile) { |_| } # initialize tempfile as a ZIP file
    tempfile
  end
end
