module Procedo
  module Engine
    class Intervention
      class Reading
        attr_accessor :value
        attr_reader :parameter, :id, :reference, :indicator

        delegate :intervention, to: :parameter
        delegate :name, :datatype, to: :indicator

        def initialize(parameter, id, attributes = {})
          unless parameter.is_a?(Procedo::Engine::Intervention::Parameter)
            fail "Invalid parameter: #{parameter.inspect}"
          end
          @parameter = parameter
          @id = id.to_s
          self.indicator_name = attributes[:indicator_name]
          @reference = parameter.reference.reading(name)
          unless reference
            fail 'Cannot find reference for: ' + attributes.inspect
          end
          if measure?
            if attributes[:measure_value_value] && attributes[:measure_value_unit]
              @value = attributes[:measure_value_value].to_d.in(attributes[:measure_value_unit])
            end
          else
            value = attributes["#{datatype}_value".to_sym]
            @value = if [:point, :geometry, :multi_polygon].include?(datatype)
                       puts value.inspect.yellow
                       v = Charta.new_geometry(v)
                       v.srid = 4326 if v.srid == 0
                       v
                     elsif datatype == :integer
                       value.to_i
                     elsif datatype == :decimal
                       value.to_d
                     elsif datatype == :boolean
                       %w(1 true t ok yes).include?(value.downcase)
                     elsif datatype == :choice
                       value.blank? ? nil : value.to_sym
                     else
                       value
                     end
          end
        end

        def indicator_name=(name)
          @indicator = Nomen::Indicator.find!(name)
        end

        def value=(value)
          @value = value
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
          elsif [:point, :geometry, :multi_polygon].include?(datatype)
            if reference.hidden?
              hash["#{datatype}_value".to_sym] = @value.to_ewkt
            else
              hash["#{datatype}_value".to_sym] = @value.to_json
            end
          else
            hash["#{datatype}_value".to_sym] = @value
          end
          hash
        end

        def measure?
          datatype == :measure?
        end
      end
    end
  end
end
