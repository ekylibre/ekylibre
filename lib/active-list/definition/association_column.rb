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
          else
            raise ArgumentError, "Only belongs_to are usable. Can't handle: #{reflection.macro} :#{reflection.name}."
          end
        else
          raise UnknownReflection, "Reflection #{reflection_name} cannot be found for #{table.model.name}."
        end
        unless @label_method = @options.delete(:label_method)
          columns = @reflection.class_name.constantize.columns_definition.keys.map(&:to_sym)
          columns += @reflection.class_name.constantize.instance_methods.map(&:to_sym)
          unless @label_method = [:full_name, :label, :name, :number, :coordinate].detect{|m| columns.include?(m)}
            raise ArgumentError, ":label_method option must be given for association #{name}. (#{columns.inspect})"
          end
        end
      end


      # Code for rows
      def datum_code(record = 'record_of_the_death', child = false)
        code = ""
        if child
          if @options[:children].is_a?(Symbol)
            code = "#{record}.#{@options[:children]}"
          end
        else
          code = "#{record}.#{@name}"
        end
        return code.c
      end




    end

  end
end
