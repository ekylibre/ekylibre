module Procedo
  module Engine
    # This module all functions accessible through formula language
    module Functions
      class << self
        # Test if population counting is as specified for given product
        def population_counting_is(product, expected)
          ((product && product.population_counting.to_sym) == expected ? 1 : 0)
        end

        # return a sum of population
        def population_count(set)
          list = set.map do |parameter|
            unless parameter.is_a?(Procedo::Engine::Intervention::ProductParameter)
              raise 'Invalid parameter. Only product_parameter wanted. Got: ' + parameter.class.name
            end
            (parameter.product ? parameter.product.population : nil)
          end
          list.compact!
          return 0.0 if list.empty?
          list.sum
        end

        # Sums indicator values for a set of product
        def sum(set, indicator_name, unit = nil)
          indicator = Nomen::Indicator.find!(indicator_name)
          raise 'Only measure indicator can use this function' unless indicator.datatype == :measure
          list = set.map do |parameter|
            unless parameter.is_a?(Procedo::Engine::Intervention::ProductParameter)
              raise 'Invalid parameter. Only product_parameter wanted. Got: ' + parameter.class.name
            end
            (parameter.product ? parameter.product.get(indicator.name) : nil)
          end
          list.compact!
          return 0.0 if list.empty?
          list.sum.to_d(unit ? unit : indicator.unit)
        end

        def sum_working_zone_areas(set, unit = nil)
          list = set.map do |parameter|
            unless parameter.is_a?(Procedo::Engine::Intervention::ProductParameter)
              raise 'Invalid parameter. Only product_parameter wanted. Got: ' + parameter.class.name
            end
            parameter.working_zone ? parameter.working_zone.area : nil
          end
          list.compact!
          return 0.0 if list.empty?
          list.sum.to_d(unit || :square_meter)
        end

        def merge_working_zones(set)
          zone = nil
          set.each do |parameter|
            unless parameter.is_a?(Procedo::Engine::Intervention::ProductParameter)
              raise 'Invalid parameter. Only product_parameter wanted. Got: ' + parameter.class.name
            end
            zone = zone.nil? ? parameter.working_zone : zone.merge(parameter.working_zone)
          end
          zone
        end

        # Returns a set composed of sibling parameter
        def siblings(parameter, set)
          children(parent(parameter), set)
        end

        def first(set)
          set.first
        end

        def first_product_of(set)
          set.parameters.first.product if set.parameters.first
        end

        def parent(parameter)
          parameter.group
        end

        def children(group, set)
          set.build(group.children(set.parameter_name))
        end

        def area(shape)
          return shape.area.to_f(:square_meter)
        rescue
          raise Procedo::Errors::FailedFunctionCall
        end

        def intersection(shape, other_shape)
          return shape.intersection(other_shape)
        rescue
          raise Procedo::Errors::FailedFunctionCall
        end

        def members_count(group)
          if group.present?
            value = group.actor.members_at(group.now).count.to_i
            return (value > 0 ? value : 0)
          else
            return 0
          end
        rescue
          raise Procedo::Errors::FailedFunctionCall
        end

        def contents_count(container)
          return container.actor.containeds.count(&:available?)
        rescue
          raise Procedo::Errors::FailedFunctionCall
        end
      end
    end
  end
end
