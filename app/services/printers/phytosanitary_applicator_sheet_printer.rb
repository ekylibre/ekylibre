# frozen_string_literal: true

module Printers
  class PhytosanitaryApplicatorSheetPrinter < PrinterBase
    def initialize(*_args, intervention:, template:, **_options)
      super(template: template)
      @intervention = intervention
    end

    attr_reader :intervention

    def generate(r)

      r.add_field :activity_name, general_informations.fetch(:activity_name)
      r.add_field :total_area, general_informations.fetch(:total_area)
      r.add_field :date, general_informations.fetch(:date)
      r.add_field :tractor_name, general_informations.fetch(:tractor_name)
      r.add_field :sprayer_name, general_informations.fetch(:sprayer_name)
      r.add_field :worker_name, general_informations.fetch(:worker_name)

      r.add_table('working_periods', working_periods, header: true) do |t|
        t.add_field(:started_at) { |wp| wp[:started_at] }
        t.add_field(:duration) { |wp| wp[:duration] }
      end
      r.add_field :total_duration, working_periods.sum{ |wp| wp[:duration] }.to_f

      r.add_table('spraying_settings', parameter_settings, header: true) do |t|
        t.add_field(:name) { |ps| ps[:name] }
        t.add_field(:nozzle_color) { |ps| ps[:nozzle_type] }
        t.add_field(:nozzle_count) { |ps| ps[:nozzle_count] }
        t.add_field(:width) { |ps| ps[:width] }
        t.add_field(:spray_pressure) { |ps| ps[:spray_pressure] }
        t.add_field(:ground_speed) { |ps| ps[:ground_speed] }
        t.add_field(:engine_speed) { |ps| ps[:engine_speed] }
        t.add_field(:row_count) { |ps| ps[:row_count] }
      end

      r.add_table('intervention', interventions, header: true) do |t|
        t.add_field(:working_zone_area) { |intervention| intervention[:working_zone_area] }
        t.add_field(:spray_mix_volume_area_density) { |intervention| intervention[:spray_mix_volume_area_density] }
        t.add_field(:total_spray_mix_volume) { |intervention| intervention[:total_spray_mix_volume] }
        t.add_table('intervention_products_doses', :intervention_products_doses) do |tt|
          tt.add_field(:product_name) { |product_dose| product_dose[:name] }
          tt.add_field(:product_dose) { |product_dose| product_dose[:dose] }
        end
      end

      r.add_table('sprayer', doses, header: true) do |t|
        t.add_field(:name) { |dose| dose[:name] }
        t.add_field(:spray_mix_volume) { |dose| dose[:spray_mix_volume] }
        t.add_table('sprayer_products_doses', :products) do |tt|
          tt.add_field(:product_name) { |spd| spd[:product_name] }
          tt.add_field(:product_dose) { |spd| spd[:product_dose] }
        end
      end
    end

    def parameter_settings
      sprayer_row_count = Maybe(sprayer_equipment&.rows_count).or_else('?')
      intervention.parameter_settings.map do |p|
        p.settings.each_with_object({ name: p.name, row_count: sprayer_row_count }){ |s, h| h[s.indicator.name.to_sym] = s.value.is_a?(Measure) ? s.value.to_f : s.value }
      end
    end

    def interventions
      intervention_product_doses = intervention.inputs.map { |i| { dose: i.input_quantity_per_area.round_l, name: i.product.name }}
      decorated_intervention = intervention.decorate
      spray_mix_volume_area_density = intervention.settings.first&.value&.round_l
      [
        {
          working_zone_area: decorated_intervention.sum_targets_working_zone_area.round_l,
          spray_mix_volume_area_density: Maybe(spray_mix_volume_area_density).or_else('?'),
          total_spray_mix_volume: Maybe(total_spray_mix_volume&.round_l).or_else('?'),
          intervention_products_doses: intervention_product_doses
        }
      ]
    end

    def sprayer_equipment
      @sprayer_equipment ||= intervention.tools.find_by(reference_name: :sprayer)&.product
    end

    def doses
      sprayer_volume = sprayer_equipment.nominal_storable_net_volume if sprayer_equipment
      spray_mix_volume_area_density = intervention.settings.first&.value
      if sprayer_volume.nil? || total_spray_mix_volume.nil?
        return [
            {
              name: "?",
              spray_mix_volume: '?',
              products: [{ product_dose: '?', product_name: '?' }]
            }
          ]
      end
      sprayer_volume_in_liter = sprayer_volume.in(:liter)

      doses = Array.new(total_spray_mix_volume / sprayer_volume_in_liter, sprayer_volume_in_liter).push(total_spray_mix_volume.to_f % sprayer_volume_in_liter.to_f)

      doses.map.with_index do |dose, i|
        {
          name: "Dose n°#{i+1}",
          spray_mix_volume: dose.in(:liter).round_l,
          products: @intervention.inputs.map do |i|
            product_dose = (i.input_quantity_per_area.to_f * ( dose.in(:liter).to_f / spray_mix_volume_area_density.to_f))
                             .in(i.product.conditioning_unit.onoma_reference_name)
                             .round_l
            { product_dose: product_dose, product_name: i.product.name }
          end
        }
      end
    end

    def total_spray_mix_volume
      return @total_spray_mix_volume if @total_spray_mix_volume.present?

      spray_mix_volume_area_density = intervention.settings.first&.value&.in(:liter_per_hectare)
      targets_working_zone = intervention.decorate.sum_targets_working_zone_area.in(:hectare)
      if spray_mix_volume_area_density.present?
        @total_spray_mix_volume = (spray_mix_volume_area_density.to_f * targets_working_zone.to_f).in(:liter)
      end
    end

    def general_informations
      @general_informations ||= {
        activity_name: intervention.activities.pluck(:name).join(','),
        total_area: intervention.decorate.sum_targets_working_zone_area.round_l,
        date: Time.zone.now.l,
        tractor_name: intervention.tools.where(reference_name: 'tractor').collect(&:product).map(&:name).join(', '),
        sprayer_name: intervention.tools.where(reference_name: 'sprayer').collect(&:product).map(&:name).join(', '),
        worker_name: intervention.doers.collect(&:product).map(&:name).join(', '),
      }
    end

    def working_periods
      @working_periods ||= intervention.working_periods.map do |wp|
        {
          started_at: wp.started_at.l,
          duration: wp.duration&.in(:second)&.convert(:hour).to_f
        }
      end
    end

    def document_name
      template.nature.human_name.to_s
    end
  end
end
