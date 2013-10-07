module ActiveList

  class Table
    attr_reader :name, :model, :options, :id, :columns, :parameters

    @@current_id = 0

    def initialize(name, model = nil, options = {})
      @name    = name
      @model   = model || name.to_s.classify.constantize
      @options = options
      @paginate = !(@options[:pagination]==:none || @options[:paginate].is_a?(FalseClass))
      @options[:renderer] ||= :simple_renderer
      @options[:per_page] = 20 if @options[:per_page].to_i <= 0
      @options[:page] = 1 if @options[:page].to_i <= 0
      @columns = []
      @current_id = 0
      @id = @@current_id.to_s(36).to_sym
      @@current_id += 1
      @parameters = {:sort => :to_s, :dir => :to_s}
      @parameters.merge!(:page => :to_i, :per_page => :to_i) if self.paginate?
    end

    def new_id
      id = @@current_id.to_s(36).to_sym
      @@current_id += 1
      return id
    end

    # def new_column_id
    #   @current_column_id ||= 0
    #   id = @current_column_id.to_s(36).to_sym
    #   @current_column_id += 1
    #   return id
    # end

    def model_columns
      @model.columns_definition.values
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

    def load_default_columns
      for column in self.model_columns
        reflections = @model.reflections.values.select{|r| r.macro == :belongs_to and r.foreign_key.to_s == column.name.to_s}
        if reflections.size == 1
          reflection = reflections.first
          columns = reflection.class_name.constantize.columns.collect{ |c| c.name.to_s }
          self.column([:label, :name, :code, :number].detect{ |l| columns.include?(l.to_s) }, :through => reflection.name, :url => true)
        else
          self.column(column.name)
        end
      end
      return true
    end

  end


  class Column
    attr_accessor :name, :options, :table
    attr_reader :id

    def initialize(table, name, options={})
      @table   = table
      @name    = name
      @options = options
      # @column  = @table.model.columns.detect{|c| c.name.to_s == @name.to_s }
      @column  = @table.model.columns_definition[@name.to_s]
      @id = name # @table.new_column_id(name, options)
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

require "active-list/columns/data_column"
require "active-list/columns/action_column"
require "active-list/columns/field_column"
