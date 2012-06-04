module List

  class Table
    attr_reader :name, :model, :options, :id, :columns, :parameters
    
    @@current_id = 0

    def initialize(name, model, options)
      @name    = name
      @model   = model
      @options = options
      @paginate = !(@options[:pagination]==:none || @options[:paginate].is_a?(FalseClass))
      @options[:renderer] ||= :simple_renderer
      @options[:per_page] = 25 if @options[:per_page].to_i <= 0
      @options[:page] = 1 if @options[:page].to_i <= 0
      @columns = []
      @current_id = 0
      @id = @@current_id.to_s(36).to_sym
      @@current_id += 1
      @parameters = {:sort=>:to_s, :dir=>:to_s}
      @parameters.merge!(:page=>:to_i, :per_page=>:to_i) if self.paginate?
    end

    def new_id
      id = @current_id.to_s(36).to_sym
      @current_id += 1
      return id
    end

    def sortable_columns
      @columns.select{|c| c.sortable?}
    end

    def exportable_columns
      @columns.select{|c| c.exportable?}
    end

    def paginate?
      @paginate
    end

  end

  
  class Column
    attr_accessor :name, :options, :table
    attr_reader :id
    
    def initialize(table, name, options={})
      @table   = table
      @name    = name
      @options = options
      @column  = @table.model.columns_hash[@name.to_s]
      @id = @table.new_id
    end

    def header_code
      raise NotImplementedError.new("#{self.class.name}#header_code is not implemented.")
    end
    
    def sortable?
      false
    end
    
    def exportable?
      false
    end

    # Unique identifier of the column in the application
    def unique_id
      "#{@table.name}-#{@id}"
    end

    # Uncommon but simple identifier for CSS class uses
    def simple_id
      "_#{@table.id}_#{@id}"
    end

  end

end

require "list/columns/data_column"
require "list/columns/action_column"
require "list/columns/field_column"
