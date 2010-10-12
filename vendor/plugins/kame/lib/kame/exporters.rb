module Kame

  mattr_reader :exporters
  @@exporters = {}

  def self.register_exporter(name, exporter)
    raise ArgumentError.new("An exporter must be Kame::Exporter") unless exporter.is_a? Kame::Exporter
    @exporters[name] = exporter.new
  end
  
  class Exporter
    
    def file_extension
      "txt"
    end
    
    def mime_type
      Mime::TEXT
    end
    
    def format_data_code
      raise NotImplementedError.new("#{self.class.name}#format_data_code is not implemented.")
    end
    
    def columns_to_array(definition, nature, options={})
      columns = definition.columns
      
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


end
