# encoding: UTF-8

# Register XCSV format unless is already set
Mime::Type.register("text/csv", :xcsv) unless defined? Mime::XCSV

module List
  
  class ExcelCsvExporter < List::CsvExporter

    def file_extension
      "csv"
    end

    def mime_type
      Mime::XCSV
    end

    def send_data_code(table)
      record = "r"
      code  = table.select_data_code(:paginate => false)
      code += "ic = Iconv.new('cp1252', 'utf-8')\n"
      code += "data = List::CSV.generate(:col_sep=>';') do |csv|\n"
      code += "  csv << [#{columns_to_array(table, :header, :iconv=>'ic').join(', ')}]\n"
      code += "  for #{record} in #{table.records_variable_name}\n"  
      code += "    csv << [#{columns_to_array(table, :body, :record=>record, :iconv=>'ic').join(', ')}]\n"
      code += "  end\n"
      code += "end\n"
      code += "send_data(data, :type=>#{self.mime_type.to_s.inspect}, :disposition=>'inline', :filename=>#{table.model.name}.model_name.human.gsub(/[^a-z0-9]/i,'_')+'.#{self.file_extension}')\n"
      return code
    end

  end

end

List.register_exporter(:xcsv, List::ExcelCsvExporter)
