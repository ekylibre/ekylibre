module Procedo
  module Engine
    class Intervention
      class Reading
        include Reassignable

        attr_accessor :value
        attr_reader :parameter, :id, :reference, :indicator

        delegate :intervention, to: :parameter
        delegate :name, :datatype, to: :indicator
        # delegate :depend_on?, to: :reference

        def initialize(parameter, id, attributes = {})
          unless parameter.is_a?(Procedo::Engine::Intervention::Parameter)
            raise "Invalid parameter: #{parameter.inspect}"
          end
          @parameter = parameter
          @id = id.to_s
          self.indicator_name = attributes[:indicator_name]
          @reference = parameter.reference.reading(name)
          unless reference
            raise 'Cannot find reference for: ' + attributes.inspect
          end
          if measure?
            if attributes[:measure_value_value] && attributes[:measure_value_unit]
              @value = attributes[:measure_value_value].to_d.in(attributes[:measure_value_unit])
            end
          else
            val = attributes["#{datatype}_value".to_sym]
            @value = if %i[point geometry multi_polygon].include?(datatype)
                       if val.blank? || val == 'null'
                         Charta.empty_geometry
                       else
                         val = Charta.from_geojson(val)
                         val.srid = 4326 if val.srid.zero?
                         val.convert_to(datatype)
                       end
                     elsif datatype == :integer
                       val.to_i
                     elsif datatype == :decimal
                       val.to_d
                     elsif datatype == :boolean
                       %w[1 true t ok yes].include?(val.downcase)
                     elsif datatype == :choice
                       val.blank? ? nil : val.to_sym
                     else
                       val
                     end
          end
        end

        def indicator_name=(name)
          @indicator = Nomen::Indicator.find!(name)
        end

        def value=(val)
          val = val.convert_to(:multi_polygon) if val.respond_to? :convert_to
          @value = val
          impact_dependencies!
        end

        def assign(attribute, value)
          super(attribute, value)
          impact_dependencies!
        end

        def impact_dependencies!
          reference.computations.each do |computation|
            next unless usable_computation?(computation)
            result = intervention.interpret(computation.expression_tree, env)
            computation.destinations.each do |destination|
              next unless destination == 'population'
              if parameter.quantity_population != result
                parameter.quantity_population = result
              end
            end
          end
        end

        def usable_computation?(computation)
          return true unless computation.condition?
          intervention.interpret(computation.condition_tree, env)
        end

        def env
          parameter.env.merge(value: @value)
        end

        def to_hash
          hash = {
            indicator_name: name,
            indicator_datatype: datatype
          }
          if measure?
            hash[:measure_value_value] = @value.to_d.to_s.to_f
            hash[:measure_value_unit] = @value.unit
          elsif %i[point geometry multi_polygon].include?(datatype)
            hash["#{datatype}_value".to_sym] = @value.to_json
          else
            hash["#{datatype}_value".to_sym] = @value
          end
          hash
        end
        alias to_attributes to_hash

        def measure?
          datatype == :measure
        end
      end
    end
  end
end
