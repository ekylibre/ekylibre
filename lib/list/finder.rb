module List

  # Manage data query
  class Table

    # Generate select code for the table taking all parameters in account
    def select_data_code(options = {})
      paginate = (options.has_key?(:paginate) ? options[:paginate] : self.paginate?)
      # Check order
      unless self.options.keys.include?(:order)
        columns = self.table_columns
        if columns.size > 0
          self.options[:order] = self.model.connection.quote_column_name(columns[0].name.to_s)
        else
          raise ArgumentError.new("Option :order is needed for the list :#{self.name}")
        end
      end

      # Find data
      query_code = "#{self.model.name}"
      query_code << ".select(#{self.select_code})" if self.select_code
      query_code << ".where(#{self.conditions_code})" unless self.options[:conditions].blank?
      query_code << ".joins(#{self.options[:joins].inspect})" unless self.options[:joins].blank?
      query_code << ".includes(#{self.includes_hash.inspect})"

      code = ""
      code << "#{self.records_variable_name}_count = #{query_code}.count\n"
      if paginate
        code << "#{self.records_variable_name}_limit = (list_params[:per_page]||25).to_i\n"
        code << "#{self.records_variable_name}_page = (list_params[:page]||1).to_i\n"
        code << "#{self.records_variable_name}_offset = (#{self.records_variable_name}_page-1)*#{self.records_variable_name}_limit\n"
        code << "#{self.records_variable_name}_last = (#{self.records_variable_name}_count.to_f/#{self.records_variable_name}_limit).ceil.to_i\n"
        code << "return #{self.view_method_name}(options.merge(:page=>1)) if 1 > #{self.records_variable_name}_page or #{self.records_variable_name}_page > #{self.records_variable_name}_last\n"
      end
      code << "#{self.records_variable_name} = #{query_code}"
      if paginate
        code << ".offset(#{self.records_variable_name}_offset)"
        code << ".limit(#{self.records_variable_name}_limit)"
      end
      code << ".order(order)||{}\n"
      return code
    end
   
    protected

    # Compute includes Hash
    def includes_hash
      hash = {}
      for column in self.columns
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
    def conditions_code
      conditions = self.options[:conditions]
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
      return code
    end
   
    def select_code
      return nil unless self.options[:distinct] or self.options[:select]
      code  = ""
      code << "DISTINCT " if self.options[:distinct]
      code << "#{self.model.table_name}.*"
      if self.options[:select]
        code << self.options[:select].collect{|k, v| ", #{k[0].to_s+'.'+k[1].to_s} AS #{v}" }.join
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



