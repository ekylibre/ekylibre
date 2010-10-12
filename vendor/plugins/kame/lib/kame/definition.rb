module Kame

  class Table
    attr_reader :name, :model, :options
    attr_reader :columns
    
    def initialize(name, model, options)
      @name    = name
      @model   = model
      @options = options
      @options[:finder]   ||= :will_paginate_finder
      @options[:renderer] ||= :simple_renderer
      @columns = []
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
    
    def sortable?
      false
    end

  end

end

require "kame/columns/data_column"
require "kame/columns/action_column"
