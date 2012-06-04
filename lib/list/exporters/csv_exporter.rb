module List
  
  class CsvExporter < List::Exporter

    def file_extension
      "csv"
    end

    def mime_type
      Mime::CSV
    end

    def send_data_code(table)
      record = "r"
      code  = table.select_data_code(:paginate => false)
      code += "data = List::CSV.generate do |csv|\n"
      code += "  csv << [#{columns_to_array(table, :header).join(', ')}]\n"
      code += "  for #{record} in #{table.records_variable_name}\n"  
      code += "    csv << [#{columns_to_array(table, :body, :record=>record).join(', ')}]\n"
      code += "  end\n"
      code += "end\n"
      code += "send_data(data, :type=>#{self.mime_type.to_s.inspect}, :disposition=>'inline', :filename=>#{table.model.name}.model_name.human.gsub(/[^a-z0-9]/i,'_')+'.#{self.file_extension}')\n"
      return code
    end

  end

end

List.register_exporter(:csv, List::CsvExporter)
