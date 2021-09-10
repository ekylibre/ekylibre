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
          indicator = Onoma::Indicator.find!(indicator_name)
          raise 'Only measure indicator can use this function' unless indicator.datatype == :measure

          list = set.map do |parameter|
            unless parameter.is_a?(Procedo::Engine::Intervention::ProductParameter)
              raise 'Invalid parameter. Only product_parameter wanted. Got: ' + parameter.class.name
            end

            (parameter.product ? parameter.product.get(indicator.name) : nil)
          end
          list.compact!
          return 0.0 if list.empty?

          list.sum.to_d(unit || indicator.unit)
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

          list.sum.in(:square_meter).to_d(unit || :square_meter)
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

        # WIP / # TODO
        # puts call in xml procedure as :
        # computed_complanted_plant_by_target(siblings(SELF, plant), SELF, siblings(SELF, plants))
        # it's return the number (population) of complanted plant (input) divided by target.working_zone / target(s).working_zone by target
        # to store complanted_vine_stock for each plant
        # procedure = vine_complanting
        def computed_complanted_plant_by_target(set, parameter, inputs)
          # get sum of all working zone
          puts "set [siblings(SELF, plant)] : #{set}".inspect.red
          puts "parameter [SELF] : #{parameter}".inspect.yellow
          working_zones_area = sum_working_zone_areas(set)
          puts "working_zones_area : #{working_zones_area}".inspect.green
          working_zone_area = parameter.working_zone.area
          puts "working_zone_area : #{working_zone_area}".inspect.red
          # sum of population of inputs
          list = set.map do |input_parameter|
            unless input_parameter.is_a?(Procedo::Engine::Intervention::ProductParameter)
              raise 'Invalid parameter. Only product_parameter wanted. Got: ' + input_parameter.class.name
            end

            input_parameter.population || nil
          end
          list.compact!
          (list.sum.to_d * (working_zone_area / working_zones_area)).to_d
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
          shape.area.in(:square_meter).to_f(:square_meter)
        rescue
          raise Procedo::Errors::FailedFunctionCall.new(:area, shape)
        end

        def intersection(shape, other_shape)
          shape.intersection(other_shape)
        rescue
          raise Procedo::Errors::FailedFunctionCall.new(:intersection, shape, other_shape)
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
          raise Procedo::Errors::FailedFunctionCall.new(:members_count, set)
        end

        def contents_count(container)
          container.actor.containeds.count(&:available?)
        rescue
          raise Procedo::Errors::FailedFunctionCall.new(:contents_count, container)
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

        def variety_of(product)
          product.variety
        rescue
          raise Procedo::Errors::FailedFunctionCall.new(:variant_of, product)
        end

        def variant_of(product)
          return product.member_variant unless product.nil?
        rescue
          raise Procedo::Errors::FailedFunctionCall.new(:variant_of, product)
        end

        def father_of(vial)
          vial.mother.last_transplantation.input.father || vial.mother.last_insemination.input.producer
        rescue
          raise Procedo::Errors::FailedFunctionCall.new(:father_of, vial)
        end

        def mother_of(vial)
          vial.mother.last_transplantation.input.mother || vial.mother
        rescue
          raise Procedo::Errors::FailedFunctionCall.new(:mother_of, vial)
        end

        # return first date as Datetime object
        def intervention_started_at(set)
          set.collect { |h| DateTime.parse(h[:started_at]) }.min
        end

        # return last date as Datetime object
        def intervention_stopped_at(set)
          set.collect { |h| DateTime.parse(h[:stopped_at]) }.max
        end

        # @param [Product] product
        # @param [Array<Symbol>] dimensions
        # @return [Integer] 1 for true, 0 for false
        def product_usages_among_dimensions(product, *dimensions)
          phyto = product.phytosanitary_product
          return 1 if phyto.nil?

          usages = phyto.usages
          return 1 if usages.empty?

          usage_units = usages.pluck(:dose_unit).uniq.compact
          checks = usage_units.any? do |usage_unit|
            unit = Onoma::Unit.find(usage_unit)
            dimensions.include?(unit.base_dimension.to_sym) || dimensions.include?(unit.dimension.to_sym)
          end

          checks || usage_units.empty? ? 1 : 0
        end

        def grain_indicators_present(product)
          check = (product.net_mass.positive? && product.thousand_grains_mass.positive?) || product.grains_count.positive?
          check ? 1 : 0
        end
      end
    end
  end
end
