module Kame
  
  class CsvExporter < Kame::Exporter

    def file_extension
      "csv"
    end

    def mime_type
      Mime::CSV
    end

    def format_data_code(table, variable_name)
      record = "record"
      code  = "#{variable_name} = FasterCSV.generate do |csv|\n"
      code += "  csv << [#{columns_to_array(definition, :header).join(', ')}]\n"
      code += "  for #{record} in #{table.records_variable_name}\n"  
      code += "    csv << [#{columns_to_csv(definition, :body, :record=>record).join(', ')}]\n"
      code += "  end\n"
      code += "end\n"
      return code
    end

  end

end

Kame.register_exporter(:csv, CsvExporter)
