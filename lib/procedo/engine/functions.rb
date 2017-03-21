# coding: utf-8
module Procedo
  module Engine
    # This module all functions accessible through formula language
    module Functions
      class << self
        def derives_from(value)
          value.blank? ? '(false)' : "derives from #{value}"
        end

        def derivative_of(product_or_set)
          return product_or_set.derivative_of if product_or_set.respond_to? :derivative_of
          return nil if product_or_set.blank?
          set = product_or_set.to_a
          variety = set.present? ? Nomen::Variety.lowest_common_ancestor_of(*set.map(&:derivative_of).compact) : nil
          variety && variety.name
        rescue
          raise Procedo::Errors::FailedFunctionCall
        end

        def variety_of(product_or_set)
          return product_or_set.variety if product_or_set.respond_to? :variety
          return nil if product_or_set.blank?
          set = product_or_set.to_a
          variety = set.present? ? Nomen::Variety.lowest_common_ancestor_of(*set.map(&:variety).compact) : nil
          variety && variety.name
        rescue
          raise Procedo::Errors::FailedFunctionCall
        end

        def setting_value(settings)
          return settings.value if settings.respond_to?(:value)
          params = settings.parameters
          params.length > 1 ? params.map(&:value) : params.first && params.first.value

        def miscibility(set)
          products = set.map do |parameter|
            next parameter.variant if parameter.respond_to? :variant
            parameter.product
          end
          PhytosanitaryMiscibility.new(products.compact).validity
        end

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

        def first_product_of(set_or_product)
          if set_or_product.respond_to?(:product) && !set_or_product.is_a?(Array)
            parameter = set_or_product
            parameter.product
          else
            set = set_or_product
            set.respond_to?(:parameters) ? set.parameters.first.product : set.first.product
          end
        end

        def last_product_of(set_or_product)
          if set_or_product.respond_to?(:product) && !set_or_product.is_a?(Array)
            parameter = set_or_product
            parameter.product
          else
            set = set_or_product
            set.respond_to?(:parameters) ? set.parameters.last.product : set.last.product
          end
        end

        def products_of(set_or_product)
          if set_or_product.respond_to?(:product) && !set_or_product.is_a?(Array)
            parameter = set_or_product
            [parameter.product]
          else
            set = set_or_product
            set.respond_to?(:parameters) ? set.parameters.map(&:product) : set.map(&:product)
          end
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

        def members_count(set)
          group = (set.is_a?(Procedo::Engine::Set) ? first_product_of(set) : set)
          if group.present?
            value = group.members_at.count.to_i
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

        # compute a name from given variant
        def output_computed_name(variant, working_periods) # working_periods
          # last_day = working_periods.last[:value]
          end_of_period = working_periods.last[:stopped_at].to_time

          # get product born on the same day
          products = []
          ps = Product.of_variant(variant).at(end_of_period).order(:born_at)
          ps.each do |p|
            products << p if p.born_at.to_date == end_of_period.to_date
          end

          # build variables
          ordered = products.compact.count + 1
          name = variant.name
          born_at = end_of_period.strftime('%d/%m/%Y')

          "#{name} n°#{ordered} #{born_at}"
        end

        def variant_of(product_or_set)
          if product_or_set.respond_to? :parameters
            set = product_or_set
            parameters = set.parameters
            parameters.map { |param| param.respond_to?(:variant) ? param.variant : param.product && param.product.variant }
          else
            product = product_or_set
            return product.member_variant unless product.nil?
          end
        end

        def father_of(vial)
          return vial.mother.last_transplantation.input.father || vial.mother.last_insemination.input.producer
        rescue
          raise Procedo::Errors::FailedFunctionCall
        end

        def mother_of(vial)
          return vial.mother.last_transplantation.input.mother || vial.mother
        rescue
          raise Procedo::Errors::FailedFunctionCall
        end

        # return first date as Datetime object
        def intervention_started_at(set)
          set.collect { |h| DateTime.parse(h[:started_at]) }.min
        end

        # return last date as Datetime object
        def intervention_stopped_at(set)
          set.collect { |h| DateTime.parse(h[:stopped_at]) }.max
        end
      end
    end
  end
end
