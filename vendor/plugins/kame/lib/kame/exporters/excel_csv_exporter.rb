module Kame
  
  class ExcelCsvExporter < Kame::Exporter

    def file_extension
      "csv"
    end

    def mime_type
      Mime::CSV
    end

    def format_data_code(table, variable_name)
      record = "record"
      code  = " ic = Iconv.new('cp1252', 'utf-8')\n"
      code += "#{variable_name} = FasterCSV.generate(:col_sep=>';') do |csv|\n"
      code += "  csv << [#{columns_to_array(definition, :header, :iconv=>'ic').join(', ')}]\n"
      code += "  for #{record} in #{table.records_variable_name}\n"  
      code += "    csv << [#{columns_to_csv(definition, :body, :record=>record, :iconv=>'ic').join(', ')}]\n"
      code += "  end\n"
      code += "end\n"
      return code
    end

  end

end

Kame.register_exporter(:csv, ExcelCsvExporter)
