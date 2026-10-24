# frozen_string_literal: true

module ActivityProductions
  # Totals of the inputs consumed by the activity productions of a campaign,
  # one row per (activity production, input product).
  #
  # Imputation follows the rules of ActivityProductions::CostsCalculation:
  # - only interventions with nature "record" and not "rejected", linked to
  #   the campaign (`Intervention.of_campaign`, campaigns_interventions);
  # - an intervention target belongs to the production its product is
  #   attached to (`products.activity_production_id`);
  # - when an intervention has several targets, each input is split between
  #   them with `intervention_parameters.imputation_ratio` (target working
  #   zone area / total targets working zone area, maintained by
  #   Intervention#handle_targets_imputation_ratio). The share of targets not
  #   attached to a production of the campaign is not imputed.
  #
  # Quantities: `quantity_population` is the quantity consumed, expressed in
  # the conditioning unit of the input product (as used by stock movements
  # and input costs). It is converted into the reference unit of the unit
  # dimension (kilogram, liter, unity...) with UnitComputation. As a row is
  # about a single product, it has a single conditioning unit: units are
  # never mixed.
  class InputTotalsCalculation
    AREA_UNIT = InterventionProductParameter::DEFAULT_WORKING_ZONE_AREA_UNIT
    NITROGEN_INDICATOR = 'nitrogen_concentration'

    # @param campaign [Campaign]
    # @param filters [Hash] activity_production_id, activity_id,
    #   input_product_id, procedure_name, started_after, started_before
    def initialize(campaign, filters = {})
      @campaign = campaign
      @filters = filters
      @unit_conversions = {}
    end

    # @return [Array<Hash>] rows sorted by activity production id then input product id
    def compute
      targets = InterventionTarget.where(intervention: interventions)
                                  .of_activity_production(productions)
                                  .includes(:product)
                                  .to_a
      return [] if targets.empty?

      targets_by_intervention = targets.group_by(&:intervention_id)
      productions_by_id = ActivityProduction.where(id: targets.map { |t| t.product.activity_production_id }.uniq)
                                            .index_by(&:id)

      rows = {}
      inputs(targets_by_intervention.keys).each do |input|
        targets_by_intervention[input.intervention_id].each do |target|
          production = productions_by_id[target.product.activity_production_id]
          row = rows[[production.id, input.product_id]] ||= new_row(production, input)
          row[:population] += input.quantity_population.to_d * target.imputation_ratio.to_d
          row[:intervention_ids] << input.intervention_id
          row[:treated_areas][[input.intervention_id, target.id]] = target.working_zone_area_value
        end
      end

      rows.sort_by { |key, _row| key }.map { |_key, row| format_row(row) }
    end

    private

      attr_reader :campaign, :filters

      def productions
        productions = ActivityProduction.of_campaign(campaign)
        productions = productions.where(id: filters[:activity_production_id]) if filters[:activity_production_id]
        productions = productions.of_activity(filters[:activity_id]) if filters[:activity_id]
        productions
      end

      def interventions
        interventions = Intervention.with_nature(:record).where.not(state: :rejected).of_campaign(campaign)
        if filters[:started_after]
          interventions = interventions.where(Intervention.arel_table[:started_at].gteq(filters[:started_after]))
        end
        if filters[:started_before]
          interventions = interventions.where(Intervention.arel_table[:started_at].lteq(filters[:started_before]))
        end
        interventions = interventions.of_nature(filters[:procedure_name]) if filters[:procedure_name]
        interventions
      end

      def inputs(intervention_ids)
        inputs = InterventionInput.where(intervention_id: intervention_ids).with_actor
        inputs = inputs.where(product_id: filters[:input_product_id]) if filters[:input_product_id]
        inputs.includes(product: :conditioning_unit, variant: :readings)
      end

      def new_row(production, input)
        {
          production: production,
          product: input.product,
          variant: input.variant,
          population: 0.to_d,
          intervention_ids: Set.new,
          treated_areas: {}
        }
      end

      def format_row(row)
        product = row[:product]
        conditioning_unit = product.conditioning_unit
        factor, base_unit_name = base_unit_conversion(conditioning_unit)
        quantity = factor ? row[:population] * factor : row[:population]
        quantity_unit = base_unit_name || conditioning_unit.reference_name || conditioning_unit.name
        areas = row[:treated_areas].values.compact
        nitrogen = nitrogen_mass(row[:variant], quantity, quantity_unit)

        {
          activity_production: { id: row[:production].id, name: row[:production].name, activity_id: row[:production].activity_id },
          input: { product_id: product.id, name: product.name, variant_id: row[:variant]&.id, variant_name: row[:variant]&.name },
          quantity_value: quantity.round(4).to_f,
          quantity_unit: quantity_unit,
          conditioning_quantity_value: row[:population].round(4).to_f,
          conditioning_unit_name: conditioning_unit.name,
          interventions_count: row[:intervention_ids].size,
          treated_area_value: areas.any? ? areas.sum.round(4).to_f : nil,
          treated_area_unit: areas.any? ? AREA_UNIT.to_s : nil,
          nitrogen_value: nitrogen&.round(4)&.to_f,
          nitrogen_unit: nitrogen ? 'kilogram' : nil
        }
      end

      # @return [Array(BigDecimal, String), Array(nil, nil)] factor to the
      #   reference unit of the dimension and the name of this reference unit
      def base_unit_conversion(unit)
        @unit_conversions[unit.id] ||= begin
          base_unit_name = Unit::BASE_UNIT_PER_DIMENSION[unit.dimension.to_s.to_sym]
          base_unit_name ? [UnitComputation.dimension_base_unit_factor(unit).to_d, base_unit_name] : [nil, nil]
        end
      end

      # Units of nitrogen (kg N), as in ActivityProduction#soil_enrichment_indicator_content_per_area:
      # input mass (kg) x nitrogen_concentration of the variant. Only for
      # inputs measured by mass with a non-zero concentration.
      # @return [BigDecimal, nil]
      def nitrogen_mass(variant, quantity, quantity_unit)
        return nil unless variant && quantity_unit == 'kilogram'

        reading = variant.readings.detect { |r| r.indicator_name == NITROGEN_INDICATOR }
        concentration = reading&.value
        return nil unless concentration.is_a?(Measure) && concentration.to_d(:unity).positive?

        quantity * concentration.to_d(:unity)
      end
  end
end
