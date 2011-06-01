module Kame

  class Table
    attr_reader :name, :model, :options, :id, :columns, :parameters
    
    @@current_id = 0

    def initialize(name, model, options)
      @name    = name
      @model   = model
      @options = options
      @options[:finder] = ((@options[:pagination]==:none or !defined?(WillPaginateFinder)) ? :simple_finder : :will_paginate_finder)
      @options[:renderer] ||= :simple_renderer
      @options[:per_page] = 25 if @options[:per_page].to_i <= 0
      @options[:page] = 1 if @options[:page].to_i <= 0
      @columns = []
      @current_id = 0
      @id = @@current_id.to_s(36).to_sym
      @@current_id += 1
      @parameters = {:sort=>:to_s, :dir=>:to_s}
      @parameters.merge!(:page=>:to_i, :per_page=>:to_i) if self.finder.paginate?
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

    def joins(j=nil)
      j ||= @options[:joins]
      h = {}
      if j.is_a? Symbol
        h[j] = {}
      elsif j.is_a? Array
        for x in j
          if x.is_a?(Symbol)
            h[x] = {}
          elsif x.is_a? Hash
            h.merge(self.joins(x))
          else
            raise ArgumentError.new("j must be a Symbol or a Hash in an Array (#{j.class}:#{j.inspect})")
          end
        end
      elsif j.is_a? Hash
        for k, v in j
          h[k] = self.joins(v)
        end
      elsif not j.nil? and not j.is_a?(String)
        raise ArgumentError.new("j must be a Symbol, an Array or a Hash (#{j.class}:#{j.inspect})")
      end
      return h
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

require "kame/columns/data_column"
require "kame/columns/action_column"
require "kame/columns/field_column"
