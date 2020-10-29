module Procedo
  module Engine
    # This module all functions accessible through formula language
    module Functions
      class << self
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
          return shape.area.in(:square_meter).to_f(:square_meter)
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

        def variety_of(product)
          return product.variety
        rescue
          raise Procedo::Errors::FailedFunctionCall
        end

        def variant_of(product)
          return product.member_variant unless product.nil?
          nil
        rescue
          raise Procedo::Errors::FailedFunctionCall
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

        def usage_unit_name_include(product, unit)
          variant = product.variant
          return 1 unless variant.imported_from == 'Lexicon' && variant.is_a?(Variants::Articles::PlantMedicineArticle)

          phyto = RegisteredPhytosanitaryProduct.find_by_reference_name(variant.reference_name)

          return 1 if phyto.nil?
          usages = phyto.usages
          return 1 if usages.empty?

          usage_units = usages.pluck(:dose_unit).uniq.compact
          usage_units.any? { |u| u =~ /\A#{Regexp.quote(unit)}_/ } || usage_units.empty? ? 1 : 0
        end
      end
    end
  end
end
