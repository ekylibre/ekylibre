module Kame

  mattr_reader :finders
  @@finders = {}

  def self.register_finder(name, finder)
    raise ArgumentError.new("A finder must be Kame::Finder") unless finder.ancestors.include? Kame::Finder
    @@finders[name] = finder.new
  end



  # A finder is a class which permits to produce an element pointing on the result
  # of the query defined in the options of the Kame table
  class Finder
    def select_data_code
      raise NotImplementedError.new("#{self.class.name}#select_data_code is not implemented.")
    end

    def conditions(table)
      code = ''
      code = conditions_to_code(table.options[:conditions]) if table.options[:conditions]
    end

    def paginate?
      false
    end

    # Generate the code from a conditions option
    def conditions_to_code(conditions)
      code = ''
      case conditions
      when Array
        case conditions[0]
        when String  # SQL
          code += '["'+conditions[0].to_s+'"'
          code += ', '+conditions[1..-1].collect{|p| sanitize_condition(p)}.join(', ') if conditions.size>1
          code += ']'
        when Symbol # Method
          code += conditions[0].to_s+'('
          code += conditions[1..-1].collect{|p| sanitize_condition(p)}.join(', ') if conditions.size>1
          code += ')'
        else
          raise ArgumentError.new("First element of an Array can only be String or Symbol.")
        end
      when Hash # SQL
        code += '{'+conditions.collect{|key, value| ':'+key.to_s+'=>'+sanitize_condition(value)}.join(',')+'}'
      when Symbol # Method
        code += conditions.to_s+"(options)"
      when String
        code += "("+conditions.gsub(/\s*\n\s*/,';')+")"
      else
        raise ArgumentError.new("Unsupported type for conditions: #{conditions.inspect}")
      end
      code
    end
    


    def sanitize_condition(value)
      if value.is_a? Array
        if value.size==1 and value[0].is_a? String
          value[0].to_s
        else
          value.inspect
        end
      elsif value.is_a? String
        '"'+value.gsub('"','\"')+'"'
      elsif [Date, DateTime].include? value.class
        '"'+value.to_formatted_s(:db)+'"'
      elsif value.is_a? NilClass
        'nil'
      else
        value.to_s
      end
    end


  end


end

require "kame/finders/simple_finder"
require "kame/finders/will_paginate_finder" if defined? WillPaginate



