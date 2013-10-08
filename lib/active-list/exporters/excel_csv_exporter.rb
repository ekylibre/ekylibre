# encoding: UTF-8

# Register XCSV format unless is already set
Mime::Type.register("text/csv", :xcsv) unless defined? Mime::XCSV

module ActiveList

  module Exporters

    class ExcelCsvExporter < CsvExporter

      def file_extension
        "csv"
      end

      def mime_type
        Mime::XCSV
      end

      def send_data_code
        record = "r"
        code  = generator.select_data_code(paginate: false)
        encoding = "CP1252"
        code << "data = ActiveList::CSV.generate(:col_sep => ';') do |csv|\n"
        code << "  csv << [#{columns_to_array(:header, encoding: encoding).join(', ')}]\n"
        code << "  for #{record} in #{generator.records_variable_name}\n"
        code << "    csv << [#{columns_to_array(:body, record: record, encoding: encoding).join(', ')}]\n"
        code << "  end\n"
        code << "end\n"
        code << "send_data(data, type: #{self.mime_type.to_s.inspect}, disposition: 'inline', filename: #{table.model.name}.model_name.human.gsub(/[^a-z0-9]/i,'_')+'.#{self.file_extension}')\n"
        return code.c
      end

    end

  end

end
