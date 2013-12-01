module ActiveList

  module Definition

    class AssociationColumn < DataColumn

      attr_reader :label_method, :reflection

      def initialize(table, name, options = {})
        super(table, name, options)
        unless @options[:through]
          raise ArgumentError, "Option :through must be given"
        end
        reflection_name = @options.delete(:through).to_sym
        if @reflection = @table.model.reflect_on_association(reflection_name)
          if @reflection.macro == :belongs_to
            # Do some stuff
          elsif @reflection.macro == :has_one
            # Do some stuff
          else
            raise ArgumentError, "Only belongs_to are usable. Can't handle: #{reflection.macro} :#{reflection.name}."
          end
        else
          raise UnknownReflection, "Reflection #{reflection_name} cannot be found for #{table.model.name}."
        end
        unless @label_method = @options.delete(:label_method)
          columns = @reflection.class_name.constantize.columns_definition.keys.map(&:to_sym)
          columns += @reflection.class_name.constantize.instance_methods.map(&:to_sym)
          unless @label_method = LABELS_COLUMNS.detect{|m| columns.include?(m)}
            raise ArgumentError, ":label_method option must be given for association #{name}. (#{columns.inspect})"
          end
        end
        unless @sort_column = @options.delete(:sort)
          columns = @reflection.class_name.constantize.columns_definition.keys.map(&:to_sym)
          unless @sort_column = LABELS_COLUMNS.detect{|m| columns.include?(m)}
            @sort_column =  @reflection.foreign_key.to_sym
            # Rails.logger.warn("No valid :sort option must be given for association #{name}. (#{columns.inspect})")
          end
        end
      end


      # Code for rows
      def datum_code(record = 'record_of_the_death', child = false)
        code = ""
        if child
          code = "nil"
          # if @options[:children].is_a?(FalseClass)
          #   code = "nil"
          # else
          #   code = "#{record}.#{table.options[:children]}.#{@reflection.name}.#{@options[:children] || @label_method}"
          # end
        else
          code = "(#{record}.#{@reflection.name} ? #{record}.#{@reflection.name}.#{@label_method} : nil)"
        end
        return code.c
      end

      def class_name
        return @reflection.class_name
      end

      def record_expr(record = 'record_of_the_death')
        return "#{record}.#{@reflection.name}"
      end

      def sort_expression
        if @reflection.macro == :has_one
          "#{@reflection.name.to_s.pluralize}_#{@reflection.class_name.constantize.table_name}.#{@sort_column}"
        else
          "#{@reflection.class_name.constantize.table_name}.#{@sort_column}"
        end
      end

    end

  end
end
