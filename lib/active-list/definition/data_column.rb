module ActiveList

  module Definition

    class DataColumn < AbstractColumn

      def header_code
        if @options[:label]
          "#{@options[:label].to_s.strip.inspect}.tl".c
        else
          "#{@table.model.name}.human_attribute_name(#{@name.inspect})".c
        end
      end

      # Code for exportation
      def exporting_datum_code(record='record_of_the_death', noview=false)
        datum = self.datum_code(record)
        if self.datatype == :boolean
          datum = "(#{datum} ? ::I18n.translate('list.export.true_value') : ::I18n.translate('list.export.false_value'))"
        elsif self.datatype == :date
          datum = "(#{datum}.nil? ? '' : #{datum}.l)"
        elsif self.datatype == :decimal and not noview
          currency = nil
          if currency = self.options[:currency]
            currency = currency[:body] if currency.is_a?(Hash)
            currency = :currency if currency.is_a?(TrueClass)
            currency = "#{record}.#{currency}".c if currency.is_a?(Symbol)
          end
          datum = "(#{datum}.nil? ? '' : #{datum}.l(#{'currency: ' + currency.inspect if currency}))"
        elsif @name.to_s.match(/(^|\_)currency$/) and self.datatype == :string
          datum = "(Nomen::Currencies[#{datum}] ? Nomen::Currencies[#{datum}].human_name : '')"
        elsif @name.to_s.match(/(^|\_)country$/) and  self.datatype == :string
          datum = "(Nomen::Countries[#{datum}] ? Nomen::Countries[#{datum}].human_name : '')"
        elsif @name.to_s.match(/(^|\_)language$/) and self.datatype == :string
          datum = "(Nomen::Languages[#{datum}] ? Nomen::Languages[#{datum}].human_name : '')"
        elsif self.enumerize?
          datum = "(#{datum}.nil? ? '' : #{datum}.text)"
        end
        return datum
      end

      # Returns the data type of the column if the column is in the database
      def datatype
        @options[:datatype] || (@column ? @column[:type] : nil)
      end


      def enumerize?
        return false
      end

      def numeric?
        [:decimal, :integer, :float, :numeric].include? self.datatype
      end

      # Returns the size/length of the column if the column is in the database
      def limit
        @column[:limit] if @column
      end

      # Defines if column is exportable
      def exportable?
        true
      end

      # Check if a column is sortable
      def sortable?
        #not self.action? and
        not self.options[:through] and not @column.nil?
      end

      # Generate code in order to get the (foreign) record of the column
      def record_expr(record = 'record_of_the_death')
        return record
      end

    end

  end

end
