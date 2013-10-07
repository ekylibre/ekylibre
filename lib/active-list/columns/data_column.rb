module ActiveList

  class Table

    # Retrieves all columns in database
    def table_columns
      cols = self.model_columns.map(&:name)
      @columns.select{|c| c.is_a? DataColumn and cols.include? c.name.to_s}
    end

    def data_columns
      @columns.select{|c| c.is_a? DataColumn}
    end

    def hidden_columns
      self.data_columns.select{|c| c.options[:hidden] }
    end

    # Add a new method in Table which permit to define data columns
    def column(*args)
      options = args.extract_options!
      name = args.shift
      options[:label_method] ||= name
      if name.blank?
        pair = options.first
        name = pair.map(&:to_s).join("_").to_sym
        options[:through]      = pair.first
        options[:label_method] = pair.second
      elsif options[:through]
        name = "#{options[:through]}_#{name}".to_sym
      end
      @columns << DataColumn.new(self, name, options)
    end

  end

  class DataColumn < Column

    def header_code
      if @options[:label].is_a? String
        "::I18n.translate('labels.#{@options[:label].strip}')"
      elsif through = @options[:through]
        through = [through] unless through.is_a? Array
        model, reflection = @table.model, nil
        for ref in through
          unless reflection.nil?
            model = reflection.class_name.constantize rescue nil
          end
          raise Exception.new("Unknown model #{reflection.class_name}") if model.nil?
          reflection = model.reflections[ref]
          raise Exception.new("Unknown reflection :#{ref} (#{through.inspect}) for the ActiveRecord: "+model.name) if reflection.nil?
        end
        "#{model.name}.human_attribute_name('#{reflection.name}')"
      else
        "#{@table.model.name}.human_attribute_name('#{@name}')"
      end
    end


    # Code for rows
    def datum_code(record = 'record_of_the_death', child = false)
      code = if child and @options[:children].is_a? Symbol
               "#{record}.#{@options[:children]}"
             elsif child and @options[:children].is_a? FalseClass
               "nil"
             elsif through = @options[:through] and !child
               through = [through] unless through.is_a?(Array)
               foreign_record = record
               through.each { |x| foreign_record += '.'+x.to_s }
               "(#{foreign_record}.#{@name} rescue nil)"
             else
               "#{record}.#{@name}"
             end
      return code.c
    end

    # Code for exportation
    def exporting_datum_code(record='rekord', noview=false)
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
      elsif @name.to_s.match(/(^|\_)currency$/) and self.datatype == :string and self.limit == 3
        datum = "(#{datum}.nil? ? '' : ::I18n.currency_label(#{datum}))"
      elsif @name == :country and  self.datatype == :string and self.limit == 2
        datum = "(#{datum}.nil? ? '' : ::I18n.translate('countries.'+#{datum}))"
      elsif @name == :language and self.datatype == :string and self.limit <= 8
        datum = "(#{datum}.nil? ? '' : ::I18n.translate('languages.'+#{datum}))"
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
      unless @options[:through]
        self.table.model.send(@name).send(:values)
        return true
      end
      return false
    rescue
      return false
    end

    def numeric?
      [:decimal, :integer, :float, :numeric].include? self.datatype
    end

    # Returns the size/length of the column if the column is in the database
    def limit
      @column[:limit] if @column
    end


    # Returns the class name of the used model
    def class_name
      klass = self.table.model
      if through = @options[:through]
        through = [through] unless through.is_a? Array
        for ref in through
          klass = klass.reflections[ref].class_name.constantize
        end
      end
      return klass.name
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
      if @options[:through]
        return ([record]+[@options[:through]]).flatten.join(".")
      else
        return record
      end
    end

  end

end
