module ActiveList

  # Manage data query
  class Generator

    # Generate select code for the table taking all parameters in account
    def select_data_code(options = {})
      paginate = (options.has_key?(:paginate) ? options[:paginate] : @table.paginate?)
      # Check order
      unless @table.options.keys.include?(:order)
        columns = @table.table_columns
        @table.options[:order] = (columns.size > 0 ? columns.first[:name].to_s : "#{@table.model.table_name}.id DESC")
      end

      class_name = @table.model.name
      class_name = "(controller_name != '#{class_name.tableize}' ? controller_name.to_s.classify.constantize : #{class_name})" if self.collection?

      # Find data
      query_code = "#{class_name}"
      query_code << ".select(#{self.select_code})" if self.select_code
      query_code << ".where(#{self.conditions_code})" unless @table.options[:conditions].blank?
      query_code << ".joins(#{@table.options[:joins].inspect})" unless @table.options[:joins].blank?
      unless self.includes_reflections.empty?
        expr = self.includes_reflections.inspect[1..-2]
        query_code << ".includes(#{expr})"
        query_code << ".references(#{expr})"
      end

      code = ""
      code << "#{var_name(:count)} = #{query_code}.count\n"
      if paginate
        code << "#{var_name(:limit)}  = (#{var_name(:params)}[:per_page] || 25).to_i\n"
        code << "#{var_name(:page)}   = (#{var_name(:params)}[:page] || 1).to_i\n"
        code << "#{var_name(:page)}   = 1 if #{var_name(:page)} < 1\n"
        code << "#{var_name(:offset)} = (#{var_name(:page)} - 1) * #{var_name(:limit)}\n"
        code << "#{var_name(:last)}   = (#{var_name(:count)}.to_f / #{var_name(:limit)}).ceil.to_i\n"
        code << "#{var_name(:last)}   = 1 if #{var_name(:last)} < 1\n"
        code << "return #{self.view_method_name}(options.merge(page: 1)) if 1 > #{var_name(:page)}\n"
        code << "return #{self.view_method_name}(options.merge(page: #{var_name(:last)})) if #{var_name(:page)} > #{var_name(:last)}\n"
      end
      code << "#{self.records_variable_name} = #{query_code}"
      code << ".reorder(#{var_name(:order)})"
      if paginate
        code << ".offset(#{var_name(:offset)})"
        code << ".limit(#{var_name(:limit)})"
      end
      code << " || {}\n"
      return code
    end

    protected

    # Compute includes Hash
    def includes_reflections
      hash = []
      for column in @table.columns
        if column.respond_to?(:reflection)
          hash << column.reflection.name
        end
      end
      return hash
    end


    # Generate the code from a conditions option
    def conditions_code
      conditions = @table.options[:conditions]
      code = ''
      case conditions
      when Array
        case conditions[0]
        when String  # SQL
          code << '[' + conditions.first.inspect
          code << conditions[1..-1].collect{|p| ", " + sanitize_condition(p)}.join if conditions.size > 1
          code << ']'
        when Symbol # Method
          raise "What?"
          code << conditions.first.to_s + '('
          code << conditions[1..-1].collect{|p| sanitize_condition(p)}.join(', ') if conditions.size > 1
          code << ')'
        else
          raise ArgumentError.new("First element of an Array can only be String or Symbol.")
        end
      when Hash # SQL
        code << '{' + conditions.collect{|key, value| key.to_s + ': ' + sanitize_condition(value)}.join(',') + '}'
      when Symbol # Method
        code << conditions.to_s + "(options)"
      when Code
        code << "(" + conditions.gsub(/\s*\n\s*/, ';') + ")"
      when String
        code << conditions.inspect
      else
        raise ArgumentError.new("Unsupported type for conditions: #{conditions.inspect}")
      end
      return code
    end

    def select_code
      return nil unless @table.options[:distinct] or @table.options[:select]
      code  = ""
      code << "DISTINCT " if @table.options[:distinct]
      code << "#{@table.model.table_name}.*"
      if @table.options[:select]
        code << @table.options[:select].collect{|k, v| ", #{k[0].to_s+'.'+k[1].to_s} AS #{v}" }.join
      end
      return ("'" + code + "'").c
    end


    def sanitize_condition(value)
      # if value.is_a? Array
      #   # if value.size==1 and value[0].is_a? String
      #   #   value[0].to_s
      #   # else
      #   value.inspect
      #   # end
      # elsif value.is_a? Code
      #   value.inspect
      # elsif value.is_a? String
      #   '"' + value.gsub('"', '\"') + '"'
      # els
      if [Date, DateTime].include? value.class
        '"' + value.to_formatted_s(:db) + '"'
      elsif value.is_a? NilClass
        'nil'
      else
        value.inspect
      end
    end


  end


end



