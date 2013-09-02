require 'active_support/core_ext/module/attribute_accessors'

module ActiveList

  mattr_reader :exporters
  @@exporters = {}

  def self.register_exporter(name, exporter)
    raise ArgumentError.new("ActiveList::Exporter expected (got #{exporter.name}/#{exporter.ancestors.inspect})") unless exporter.ancestors.include? ActiveList::Exporter
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
        headers << (options[:encoding] ? datum+".to_s.encode('#{options[:encoding]}')" : datum)
      end
      return headers
    end
    
    def columns_to_array(table, nature, options={})
      columns = table.exportable_columns
      
      array = []
      record = options[:record]||'rekord'
      for column in columns
        if column.is_a? ActiveList::Column
          if nature==:header
            datum = column.header_code
          else
            datum = column.exporting_datum_code(record)
          end
          array << (options[:encoding] ? datum+".to_s.encode('#{options[:encoding]}')" : datum)
        end
      end
      return array
    end

  end

end


require "active-list/exporters/open_document_spreadsheet_exporter"
require "active-list/exporters/csv_exporter"
require "active-list/exporters/excel_csv_exporter"
