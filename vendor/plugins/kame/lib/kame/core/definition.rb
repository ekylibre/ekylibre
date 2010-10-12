

module Kame

  class Table
    attr_reader :name, :model, :options
    attr_reader :columns # , :procedures
    
    def initialize(name, model, options)
      @name    = name
      @model   = model
      @options = options
      @columns = []
    end

    def table_columns
      cols = @model.columns.collect{|c| c.name}
      @columns.select{|c| c.nature == :column and cols.include? c.name.to_s}
    end
    
    
    def column(name, options={})
      @columns << DataColumn.new(self, name, options)
    end

  end

  
  class Column
    attr_accessor :name, :options
    attr_reader :nature
    
    def initialize(table, name, options={})
      @table   = table
      @name    = name
      @options = options
      @column  = @table.model.columns_hash[@name.to_s]
    end

    def header_code
      raise NotImplementedError.new("#{self.class.name}#header_code is not implemented.")
    end

  end


  class DataColumn < Column

    def header_code
      if @options[:through] and @options[:through].is_a?(Symbol)
        reflection = @table.model.reflections[@options[:through]]
        raise Exception.new("Unknown reflection :#{@options[:through].to_s} for the ActiveRecord: "+@table.model.to_s) if reflection.nil?
        if @options[:label].is_a? String
          "::I18n.translate('labels.#{@options[:label].strip}')"
        elsif reflection.macro == :has_one or @options[:label] == :column
          "#{reflection.class_name}.human_attribute_name('#{@name}')"
        else
          "#{@table.model.name}.human_attribute_name(#{@options[:through].to_s.inspect})"
        end
      elsif @options[:through] and @options[:through].is_a?(Array)
        model = @table.model
        (@options[:through].size-1).times do |x|
          model = model.reflections[@options[:through][x]].options[:class_name].constantize
        end
        reflection = @options[:through][@options[:through].size-1].to_sym
        "::I18n.translate('activerecord.attributes.#{model.name.underscore}.#{model.reflections[reflection].primary_key_name}')"
      else
        "#{@table.model.name}.human_attribute_name('#{@name}')"
      end
    end

    def datum_code(record='record', child = false)
      code = if child and @options[:children].is_a? Symbol
               "#{record}.#{@options[:children]}"
             elsif child and @options[:children].is_a? FalseClass
               "nil"
             elsif @options[:through] and !child
               through = [@options[:through]] unless @options[:through].is_a?(Array)
               foreign_record = record
               through.size.times { |x| foreign_record += '.'+through[x].to_s }
               "(#{foreign_record}.nil? ? nil : #{foreign_record}.#{@name})"
             else
               "#{record}.#{@name}"
             end
      return code
    end

    # Returns the data type of the column if the column is in the database
    def datatype
      @options[:datatype] || (@column ? @column.type : nil)
    end

    # Returns the size/length of the column if the column is in the database
    def limit
      @column.limit if @column
    end

  end

end
