module List

  mattr_reader :exporters
  @@exporters = HashWithIndifferentAccess.new

  def self.register_exporter(name, exporter)
    raise ArgumentError.new("List::Exporter expected (got #{exporter.name}/#{exporter.ancestors.inspect})") unless exporter.ancestors.include? List::Exporter
    @@exporters[name] = exporter.new(name)
  end
  
  class Exporter
    attr_reader :name

    def initialize(name)
      @name = name
    end

    def file_extension
      "txt"
    end
    
    def mime_type
      Mime::TEXT
    end

    # Not used
    # def condition
    #   "not request.xhr? and params[:format] == '#{name}'"
    # end
       
    def send_data_code(table)
      raise NotImplementedError.new("#{self.class.name}#format_data_code is not implemented.")
    end

    def columns_headers(table, options={})
      headers, columns = [], table.exportable_columns
      for column in columns
        datum = column.header_code
        headers << (options[:iconv] ? "#{options[:iconv]}.iconv("+datum+".to_s)" : datum)
      end
      return headers
    end
    
    def columns_to_array(table, nature, options={})
      columns = table.exportable_columns
      
      array = []
      record = options[:record]||'rekord'
      for column in columns
        if column.is_a? List::Column
          if nature==:header
            datum = column.header_code
          else
            datum = column.exporting_datum_code(record)
          end
          array << (options[:iconv] ? "#{options[:iconv]}.iconv("+datum+".to_s)" : datum)
        end
      end
      return array
    end

  end

end


require "list/exporters/open_document_spreadsheet_exporter"
require "list/exporters/csv_exporter"
require "list/exporters/excel_csv_exporter"
