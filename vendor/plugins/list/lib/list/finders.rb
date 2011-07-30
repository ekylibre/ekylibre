module List

  mattr_reader :finders
  @@finders = {}

  def self.register_finder(name, finder)
    raise ArgumentError.new("A finder must be List::Finder") unless finder.ancestors.include? List::Finder
    @@finders[name] = finder.new
  end



  # A finder is a class which permits to produce an element pointing on the result
  # of the query defined in the options of the List table
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


    # Compute includes Hash
    def includes(table)
      hash = {}
      for column in table.columns
        if through = column.options[:through]
          through = [through] unless through.is_a? Array
          h = hash
          for x in through
            h[x] = {} unless h[x].is_a? Hash
            h = h[x]
          end         
        end
      end
      return hash
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
    
    def select_code(table)
      return nil unless table.options[:distinct] or table.options[:select]
      code  = ""
      code += "DISTINCT " if table.options[:distinct]
      code += "#{table.model.table_name}.*"
      if table.options[:select]
        code += table.options[:select].collect{|k, v| ", #{k[0].to_s+'.'+k[1].to_s} AS #{v}" }.join
      end
      return "'"+code+"'"
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

require "list/finders/simple_finder"
require "list/finders/will_paginate_finder" if defined? WillPaginate



