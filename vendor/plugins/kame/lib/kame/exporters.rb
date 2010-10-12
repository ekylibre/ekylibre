module Kame

  mattr_reader :exporters
  @@exporters = HashWithIndifferentAccess.new

  def self.register_exporter(name, exporter)
    raise ArgumentError.new("Kame::Exporter expected (got #{exporter.name}/#{exporter.ancestors.inspect})") unless exporter.ancestors.include? Kame::Exporter
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

    def condition
      "not request.xhr? and params[:format] == '#{name}'"
    end
       
    def send_data_code(table)
      raise NotImplementedError.new("#{self.class.name}#format_data_code is not implemented.")
    end
    
    def columns_to_array(table, nature, options={})
      columns = table.data_columns
      
      array = []
      record = options[:record]||'RECORD'
      for column in columns
        if column.is_a? Kame::Column
          if nature==:header
            datum = column.header_code
          else
            datum = column.datum_code(record)
            if column.datatype == :boolean
              datum = "(#{datum} ? ::I18n.translate('kame.export.true_value') : ::I18n.translate('kame.export.false_value'))"
            end
            if column.datatype == :date
              datum = "::I18n.localize(#{datum})"
            end
            if column.datatype == :decimal
              datum = "(#{datum}.nil? ? '' : number_to_currency(#{datum}, :separator=>',', :delimiter=>'', :unit=>'', :precision=>#{column.options[:precision]||2}))"
            end
            if column.name==:country and  column.datatype == :string and column.limit == 2
              datum = "(#{datum}.nil? ? '' : ::I18n.translate('countries.'+#{datum}))"
            end
            if column.name==:language and  column.datatype == :string and column.limit <= 8
              datum = "(#{datum}.nil? ? '' : ::I18n.translate('languages.'+#{datum}))"
            end
          end
          array << (options[:iconv] ? "#{options[:iconv]}.iconv("+datum+".to_s)" : datum)
        end
      end
      return array
    end

  end

end


require "kame/exporters/csv_exporter"
require "kame/exporters/excel_csv_exporter"
