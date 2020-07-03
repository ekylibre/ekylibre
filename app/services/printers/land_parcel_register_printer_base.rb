module Printers
  class LandParcelRegisterPrinterBase < PrinterBase

    IMPLANTATION_PROCEDURE_NAMES = %w[sowing sowing_without_plant_output sowing_with_spraying mechanical_planting].freeze
    HARVESTING = %w[harvesting].freeze

    class << self
      # TODO move this elsewhere when refactoring the Document Management System
      def build_key(campaign:, activity: nil)
        if activity.present?
          "#{activity.name} - #{campaign.name}"
        else
          campaign.name
        end
      end
    end

    def compute_dataset
      productions = get_productions_for_dataset.select { |production| production.plant_farming? }

      compute_productions_dataset(productions)
    end

    def compute_productions_dataset(activity_productions)
      grouped_interventions = compute_grouped_interventions(activity_productions)

      aps_dataset = activity_productions.map { |ap| compute_ap_dataset ap, grouped_interventions }

      {
        index: [], #TODO re-enable this when the index rendering problem is fixed: build_index_dataset(aps_dataset),
        display_no_data_message: grouped_interventions.empty? ? [{}] : [],
        dataset: normalize_dataset_interventions_for_sections(aps_dataset)
      }
    end

    # @param [Array<ActivityProduction>] activity_productions
    # @retun [Hash{Plant, LandParcel => Array<Intervention>}]
    def compute_grouped_interventions(activity_productions)
      activity_productions
        .flat_map(&:interventions).uniq
        .reject { |i| i.campaigns.empty? && campaign_year != i.started_at.year } # Only happens for production that spans multiple campaigns. We only want the interventions that happened during the year.
        .flat_map { |i| i.targets.map { |t| [t.product, i] } }
        .group_by(&:first)
        .map { |key, vals| [key, vals.map(&:second)] }
        .to_h
    end

    # Compute the dataset for the given activity production
    def compute_ap_dataset(activity_production, grouped_interventions)
      activity_production = Maybe(activity_production)

      support = activity_production.support.get
      support_interventions_dataset = compute_interventions_dataset(support, grouped_interventions.fetch(support, []))

      plants = activity_production.products.plants
      plants_dataset = plants
                         .fmap { |ps| compute_plants_dataset(ps, grouped_interventions) }
                         .or_else([])

      {
        name: activity_production.name,
        production_surface_area: activity_production.net_surface_area.in_hectare.round_l,
        pac_islet: activity_production.cap_land_parcel.islet_number,
        started_on: activity_production.started_on.l,
        stopped_on: activity_production.stopped_on.l,
        cultivable_zone: activity_production.cultivable_zone.name,
        specie: activity_production.cultivation_variety.l,
        land_parcel_ift: None(),
        support_interventions: support_interventions_dataset,
        plants: plants_dataset,
        yields: compute_ap_yield(support, plants.or_else([]), grouped_interventions)
      }
    end

    # Computes the dataset for the given plants
    def compute_plants_dataset(plants, grouped_interventions)
      plants.map do |plant|
        maybe_plant = Maybe(plant)
        plant_interventions = grouped_interventions.fetch(plant, [])

        {
          name: maybe_plant.name,
          plant_surface_area: maybe_plant.net_surface_area.in_hectare.round_l,
          implanted_on: maybe_plant.born_at.to_date.l,
          stopped_on: maybe_plant.dead_at.to_date.l,
          harvested_on: harvest_period(plant_interventions),
          specie: maybe_plant.activity_production.cultivation_variety.l,
          variety: maybe_plant.variety.l,
          interventions: compute_interventions_dataset(plant, plant_interventions)
        }
      end
    end

    # Generates the harvest period for the given interventions:
    # Either a period if multiple days of juste a date if all harvest interventions are done the same day
    def harvest_period(interventions)
      harvest_interventions = Maybe(interventions).select { |i| HARVESTING.include? i.procedure_name }.fmap(&:presence)
      first, *rest = harvest_interventions.or_else { return None() }

      period = { start: first.started_at.to_date, stop: first.stopped_at.to_date }
      if rest.present?
        rest.reduce(period) { |acc, e| { start: [acc[:start], e.started_at.to_date].min, stop: [acc[:stop], e.stopped_at.to_date].max } }
      end

      if (single = period.values.uniq).count == 1
        Maybe(single.first.l)
      else
        Maybe("Du #{period[:start].l} au #{period[:stop].l}")
      end
    end

    # Computes the dataset for all given intervention relative to the given target
    # @param [Plant, LandParcel] target
    # @param [Array<Intervention>] intervention
    # @return [Array<Hash>]
    def compute_interventions_dataset(target, interventions)
      interventions.sort_by { |intervention| intervention.started_at }.map do |intervention|
        maybe_intervention = Maybe(intervention)

        maybe_actions = maybe_intervention.actions.map { |nature| I18n.t("nomenclatures.procedure_actions.items.#{nature}") }.join(', ')

        {
          number: maybe_intervention.number,
          nature: maybe_actions.fmap(&:presence).recover { maybe_intervention.procedure.human_name },
          date: maybe_intervention.started_at.to_date.l,
          tool: maybe_intervention.tools.map { |tool| tool.product.name }.join(', '),
          doer: maybe_intervention.doers.map { |doer| doer.product.name }.join(', '),
          working_area: maybe_intervention.fmap { |i| products_working_areas(i).fetch(target) }.fmap { |area| autosize_area_unit(area) }.round_l,
          inputs: compute_input_output_dataset(target, intervention)
        }
      end
    end

    def autosize_area_unit(area)
      hectares = area.in(:hectare)

      if hectares.to_d < 1
        hectares.in(:are)
      else
        hectares
      end
    end

    # Computes the dataset for all the inputs ans outputs on the given target for the given intervention
    def compute_input_output_dataset(target, intervention)
      input = compute_input_dataset(target, intervention).or_else([])
      output = compute_output_dataset(target, intervention).or_else([])
      [*input, *output]
    end

    # Computes the dataset for all the inputs on the given target for the given intervention
    # TODO handle the IFT
    def compute_input_dataset(target, intervention)
      inputs = Maybe(intervention).inputs.fmap(&:presence).catch { return None() }

      inputs.map do |input|
        maybe_input = Maybe(input)

        {
          kind: :input,
          type: maybe_input.product.nature.name,
          quantity: maybe_input.quantity.fmap { |quantity| weight_quantity_by_area(quantity, target, intervention) }.round_l,
          name: maybe_input.product.name,
          ift: None()
        }
      end
    end

    # Computes the dataset for all the outputs on the given target for the given intervention
    # TODO handle the IFT
    def compute_output_dataset(taregt, intervention)
      outputs = Maybe(intervention).outputs.fmap(&:presence).catch { return None() }

      outputs.reject { |output| output.product.is_a? Plant }.map do |output|
        maybe_output = Maybe(output)

        {
          kind: :output,
          type: maybe_output.product.nature.name,
          quantity: maybe_output.quantity.fmap { |quantity| weight_quantity_by_area(quantity, taregt, intervention) }.round_l,
          name: maybe_output.product.name,
          ift: None()
        }
      end
    end

    # Compute the yield for an activity production given its support, plants and all the interventions done
    def compute_ap_yield(support, plants, grouped_interventions)
      targets = [support, *plants]
      interventions = targets.flat_map { |t| grouped_interventions.fetch(t, []) }

      # compute yields by product and normalize for interpolation in report
      compute_yields(targets, interventions).map do |value|
        m_value = Maybe(value)

        {
          name: m_value[:product].name,
          yield: m_value[:yield].round_l,
          quantity: m_value[:quantity].fmap(&method(:auto_size_quantity_unit)).round_l,
          intervention_count: m_value[:interventions].count
        }
      end.sort_by { |v| v[:product] }
    end

    UNITS_AUTOSIZE = {
      quintal: %i[ton kilogram],
      hectoliter: %i[cubic_meter liter]
    }
    # Autimatically converts quintal/hectoliters up to tonnes or down to kilograms if the values is above or below a certain threshold
    def auto_size_quantity_unit(quantity)
      base_unit = quantity.base_unit.to_sym

      return quantity unless UNITS_AUTOSIZE.keys.include? base_unit

      if quantity.to_d > 10
        quantity.in(UNITS_AUTOSIZE[base_unit].first)
      elsif quantity.to_d < 1
        quantity.in(UNITS_AUTOSIZE[base_unit].second)
      else
        quantity
      end
    end

    # Compute the yield for each product harvested on the given targets with the given interventions
    def compute_yields(targets, interventions)
      harvest_interventions = Maybe(interventions).select { |i| HARVESTING.include? i.procedure_name }.fmap(&:presence)

      # For each output, we get quantity and total area worked
      # Then, we normalize the quantity per output (remove the per area dimention)
      # ... group by output product
      # .. and average each group
      harvest_interventions
        .flat_map(&:outputs)
        .map { |output| [output.product, weight_quantity_by_area(output.quantity, targets, output.intervention), intervention_working_area_for(targets, output.intervention), output.intervention] }
        .reject { |(_1, _2, area, _3)| area.is_none? }
        .map { |(product, quantity, area, intervention)| [product, quantity, area.get, intervention] }
        .map { |product, quantity, working_area, intervention| [product, normalize_to_base_unit(quantity, working_area), working_area, intervention] }
        .group_by(&:first)
        .map { |product, values| to_yield_dataset(product, values) }
        .or_else([])
    end

    # Simple reducer to finalize the computation of the yield for the given product
    def to_yield_dataset(product, values)
      dimensions = values.map(&:second).map(&:base_dimension).uniq
      return to_concatenated_yield_dataset(product, values) if dimensions.count > 1

      case dimensions.first
        when "mass"
          to_standard_yield_dataset product, values, base_unit: :quintal
        when "volume"
          to_standard_yield_dataset product, values, base_unit: :hectoliter
        else #unitary/none
          to_special_yield_dataset product, values
      end
    end

    def to_special_yield_dataset(product, values)
      units = values.map(&:second).map(&:base_unit).uniq

      if units.count == 1 && units.first == :unity
        to_standard_yield_dataset(product, values, base_unit: :unity)
      else
        to_concatenated_yield_dataset(product, values)
      end
    end

    def to_concatenated_yield_dataset(product, values)
      { product: product, yield: None(), quantity: values.map(&:second).map(&:round_l).join(', '), interventions: values.map(&:third).uniq }
    end

    def to_standard_yield_dataset(product, values, base_unit:)
      quantity, area = values.reduce([0.in(base_unit), 0.in(:hectare)]) { |(qt, ar), (_1, q, a, _2)| [qt +q, ar + a] }
      yieldd = area.zero? ? 0 : (quantity.to_d(base_unit) / area.to_d(:hectare)).in("#{base_unit}_per_hectare".to_sym)

      { product: product, yield: yieldd, quantity: quantity, interventions: values.map(&:third).uniq }
    end

    # Normalizes quantity to a mass unit (ex: t/ha => t)
    def normalize_to_base_unit(quantity, area)
      if quantity.has_repartition_dimension?(:surface_area)
        base_unit = quantity.base_unit
        (quantity.in("#{base_unit}_per_hectare".to_sym).to_d * area.in(:hectare).to_d).in(base_unit)
      else
        quantity
      end
    end

    # Compute the area worked by the intervention for the given parcel/plant
    def intervention_working_area_for(product_targets, intervention)
      products_working_areas(intervention)
        .select { |product_target| product_targets.include? product_target }
        .map(&:second)
        .sum
    end

    # Weight the quantity according to the ratio of the target area by the total area worked
    # by the intervention (only if the unit does not have a surface area repartition dimension)
    def weight_quantity_by_area(quantity, target, intervention)
      unless quantity.has_repartition_dimension?(:surface_area)
        quantity = quantity * product_area_ratio(target, intervention)
      end

      quantity
    end

    # Computes the ratio between the worked area of the given target over the total area worked by the intervention
    def product_area_ratio(targets, intervention)
      areas = products_working_areas(intervention)

      total_area = areas.values.sum.or_else { return 0.to_d }
      return 0.to_d if total_area.zero?

      Array(targets).map { |target| areas[target].or_else { 0.in(:hectare) } / total_area }.sum
    end

    # For each target of the intervention, compute its worked area
    def products_working_areas(intervention)
      targets_working_area(intervention)
        .map { |target, values| [target.product, values] }
        .group_by(&:first)
        .map { |key, values| [key, values.map(&:second).sum] }
        .to_h
    end

    # Maps each intervention target with its area
    def targets_working_area(intervention)
      Maybe(intervention).targets.map { |target| [target, target_working_area(target)] }
    end

    # Returns the worked area for the given target
    def target_working_area(target)
      Maybe(target).working_area.or_else(0.in_square_meter)
    end

    def build_index_dataset(aps_dataset)
      productions = aps_dataset.map do |ap|
        plants_dataset = ap.fetch(:plants).map do |plant|
          {
            plant_name: plant.fetch(:name),
            plant_surface_area: plant.fetch(:plant_surface_area),
            plant_intervention_count: Maybe(plant).fetch(:interventions).count.fmap(&method(:pluralize_intervention_count))
          }
        end
        plants_dataset = normalize_collection_for_section plants_dataset, :plants

        {
          production_name: ap.fetch(:name),
          production_surface_area: ap.fetch(:production_surface_area),
          production_intervention_count: Maybe(ap).fetch(:support_interventions).count.fmap(&method(:pluralize_intervention_count)),
          plants: plants_dataset
        }
      end
      [{ productions: productions }]
    end

    def normalize_dataset_interventions_for_sections(aps_dataset)
      # Disable filtering as LibreOffice has a bug when rendering produxtion index
      # TODO reactivate when the problem is fixed
      # aps_dataset = aps_dataset.select do |ap_dataset| # remove productions that don't have interventions
      #   ap_dataset.fetch(:support_interventions).any? || ap_dataset.fetch(:plants).flat_map { |plant| plant.fetch(:interventions) }.any?
      # end

      aps_dataset.map do |ap|
        plants = ap.fetch(:plants).map { |plant| { **plant, interventions: normalize_intervention_collection(plant.fetch(:interventions)) } }
        yields = normalize_collection_for_section ap.fetch(:yields), :yields

        {
          **ap,
          support_interventions: normalize_intervention_collection(ap.fetch(:support_interventions)),
          plants: plants,
          yields: yields
        }
      end
    end

    def normalize_intervention_collection(interventions)
      normalize_collection_for_section interventions, :interventions
    end

    def normalize_collection_for_section(collection, key)
      collection.present? ? [{ key => collection }] : []
    end

    def pluralize_intervention_count(intervention_count)
      case intervention_count
        when 0 then
          "Aucune intervention"
        when 1 then
          "1 intervention"
        else
          "#{intervention_count} interventions"
      end
    end

    def run_pdf
      company = Entity.of_company

      dataset = compute_dataset

      generate_report(template_path, multipage: true) do |r|
        # Date
        r.add_field(:document_export_date, Time.zone.now.l(format: '%d %B %Y'))

        r.add_section(:section_title, [{ index: dataset.fetch(:index, []) }]) do |ts|
          ts.add_section(:section_index, :index) do |is|
            is.add_table(:index_production_list, :productions) do |ipt|
              ipt.add_field(:production_name, &fetch(:production_name))
              ipt.add_field(:production_surface_area, &fetch(:production_surface_area))
              ipt.add_field(:production_intervention_count, &fetch(:production_intervention_count))

              ipt.add_section(:section_index_plant_list, :plants) do |siplt|
                siplt.add_table(:index_plant_list, :plants) do |iplt|
                  iplt.add_field(:plant_name, &fetch(:plant_name))
                  iplt.add_field(:plant_surface_area, &fetch(:plant_surface_area))
                  iplt.add_field(:plant_intervention_count, &fetch(:plant_intervention_count))
                end
              end
            end
          end
        end

        r.add_section(:section_no_interventions, dataset.fetch(:display_no_data_message)) do |msg|
          msg
        end

        # Productions
        r.add_section(:section_production, dataset.fetch(:dataset)) do |s|
          s.add_field(:production_name, &fetch(:name))
          s.add_field(:production_surface_area, &fetch(:production_surface_area))
          s.add_field(:pac_islet, &fetch(:pac_islet))
          s.add_field(:started_on, &fetch(:started_on))
          s.add_field(:stopped_on, &fetch(:stopped_on))
          s.add_field(:cultivable_zone, &fetch(:cultivable_zone))
          s.add_field(:specie, &fetch(:specie))
          s.add_field(:land_parcel_ift, &fetch(:land_parcel_ift))

          s.add_section(:section_yields, :yields) do |sy|
            sy.add_table(:table_yields, :yields) do |ty|
              ty.add_field(:name, &fetch(:name))
              ty.add_field(:yield, &fetch(:yield))
              ty.add_field(:quantity, &fetch(:quantity))
              ty.add_field(:intervention_count, &fetch(:intervention_count))
            end
          end

          # Interventions-table
          s.add_section(:section_production_interventions, :support_interventions) do |ss|
            ss.add_table(:production_interventions, :interventions) do |t|
              t.add_field(:number, &fetch(:number))
              t.add_field(:nature, &fetch(:nature))
              t.add_field(:date, &fetch(:date))
              t.add_field(:tool, &fetch(:tool))
              t.add_field(:doer, &fetch(:doer))
              t.add_field(:working_area, &fetch(:working_area))

              t.add_table(:production_intervention_parameter, :inputs) do |i|
                i.add_field(:type, &fetch(:type))
                i.add_field(:quantity, &fetch(:quantity))
                i.add_field(:ift, &fetch(:ift))
                i.add_field(:name, &fetch(:name))
              end
            end
          end

          s.add_section(:section_plant, :plants) do |ps|
            ps.add_field(:plant_name, &fetch(:name))
            ps.add_field(:plant_surface_area, &fetch(:plant_surface_area))
            ps.add_field(:implanted_on, &fetch(:implanted_on))
            ps.add_field(:plant_stopped_on, &fetch(:stopped_on))
            ps.add_field(:harvested_on, &fetch(:harvested_on))
            ps.add_field(:specie, &fetch(:specie))
            ps.add_field(:variety, &fetch(:variety))

            # Interventions-table
            ps.add_section(:section_plant_interventions, :interventions) do |ss|
              ss.add_table(:plant_interventions, :interventions) do |t|
                t.add_field(:number, &fetch(:number))
                t.add_field(:nature, &fetch(:nature))
                t.add_field(:date, &fetch(:date))
                t.add_field(:tool, &fetch(:tool))
                t.add_field(:doer, &fetch(:doer))
                t.add_field(:working_area, &fetch(:working_area))

                # Intervention-inputs/outputs
                t.add_table(:plant_intervention_parameter, :inputs) do |i|
                  i.add_field(:type, &fetch(:type))
                  i.add_field(:quantity, &fetch(:quantity))
                  i.add_field(:ift, &fetch(:ift))
                  i.add_field(:name, &fetch(:name))
                end
              end
            end
          end
        end

        # Footer
        r.add_field :company_name, company.name
        r.add_field :company_siret, company.siret_number
        r.add_field :company_address, company.mails.where(by_default: true).first.coordinate
        r.add_field :filename, document_name
        r.add_field :printed_at, Time.zone.now.l
      end
    end

    private

      def fetch(key, default = '_ _')
        ->(value) { value.fetch(key).or_else default }
      end

    def campaign_year
      campaign.harvest_year
    rescue StandardError => e
      Rails.logger.warn e
      nil
    end
  end
end
