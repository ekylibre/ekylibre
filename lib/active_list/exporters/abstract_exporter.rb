module ActiveList

  module Exporters

    class AbstractExporter

      attr_reader :table, :generator

      def initialize(generator)
        @generator = generator
        @table = generator.table
      end

      def file_extension
        "txt"
      end

      def mime_type
        Mime::TEXT
      end

      def send_data_code
        raise NotImplementedError, "#{self.class.name}#format_data_code is not implemented."
      end

      def columns_headers(options={})
        headers, columns = [], table.exportable_columns
        for column in columns
          datum = column.header_code
          headers << (options[:encoding] ? datum+".to_s.encode('#{options[:encoding]}')" : datum)
        end
        return headers
      end

      def columns_to_array(nature, options={})
        columns = table.exportable_columns

        array = []
        record = options[:record] || 'record_of_the_death'
        for column in columns
          if column.is_a?(ActiveList::Definition::AbstractColumn)
            if nature == :header
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
end
