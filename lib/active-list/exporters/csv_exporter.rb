module ActiveList

  module Exporters

    class CsvExporter < AbstractExporter

      def file_extension
        "csv"
      end

      def mime_type
        Mime::CSV
      end

      def send_data_code
        record = "r"
        code  = generator.select_data_code(paginate: false)
        code << "data = ActiveList::CSV.generate do |csv|\n"
        code << "  csv << [#{columns_to_array(:header).join(', ')}]\n"
        code << "  for #{record} in #{generator.records_variable_name}\n"
        code << "    csv << [#{columns_to_array(:body, record: record).join(', ')}]\n"
        code << "  end\n"
        code << "end\n"
        code << "send_data(data, type: #{self.mime_type.to_s.inspect}, disposition: 'inline', filename: #{table.model.name}.model_name.human.gsub(/[^a-z0-9]/i,'_') + '.#{self.file_extension}')\n"
        return code.c
      end

    end

  end

end
