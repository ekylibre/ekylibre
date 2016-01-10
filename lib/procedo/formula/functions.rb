module Procedo
  module Formula
    # This module all functions accessible through formula language
    module Functions
      class << self
        # Sums indicator values for a set of product
        def sum(set, indicator_name, unit = nil)
          indicator = Nomen::Indicator.find!(indicator_name)
          fail 'Only measure indicator can use this function' unless indicator.datatype == :measure
          list = set.map do |parameter|
            unless parameter.is_a?(Procedo::Engine::InterventionProductParameter)
              fail 'Invalid parameter. Only product_parameter wanted. Got: ' + parameter.class.name
            end
            parameter.get(indicator.name)
          end
          return 0.0 if list.empty?
          list.compact.sum.to_d(unit ? unit : indicator.unit)
        end

        def area(shape)
          return shape.area.to_f(:square_meter)
        rescue
          raise Procedo::FailedFunctionCall
        end

        def intersection(shape, other_shape)
          return shape.intersection(other_shape)
        rescue
          raise Procedo::FailedFunctionCall
        end

        def members_count(group)
          if group.present?
            value = group.actor.members_at(group.now).count.to_i
            return (value > 0 ? value : 0)
          else
            return 0
          end
        rescue
          raise Procedo::FailedFunctionCall
        end

        def contents_count(container)
          return container.actor.containeds.count(&:available?)
        rescue
          raise Procedo::FailedFunctionCall
        end
      end
    end
  end
end
