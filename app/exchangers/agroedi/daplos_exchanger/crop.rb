# frozen_string_literal: true

using Ekylibre::Utils::DateSoftParse

module Agroedi
  class DaplosExchanger < ActiveExchanger::Base
    class Crop < DaplosNode
      daplos_parent :exchanger

      def initialize(*args)
        super
        daplos.interventions&.each do |i|
          DaplosExchanger::DaplosIntervention.new(self, i).register
        end
      end

      def import
        return unless production_nature

        return unless activity_production

        align_activity_production_dates!

        return unless production_support &&
                      production.started_on.present? &&
                      production.stopped_on.present?

        return unless daplos.interventions.any?

        children[:interventions].each { |i| i.import; parent.w.check_point }
      end

      def period
        [started_on, stopped_on]
      end

      def started_on
        Date.soft_parse(daplos.crop_started_on)
      end
      alias_method :start, :started_on

      def stopped_on
        Date.soft_parse(daplos.crop_stopped_on)
      end
      alias_method :stop, :stopped_on

      def specie_code
        daplos.crop_specie_edicode
      end

      def production_nature
        return @production_nature if @production_nature

        specie_code = daplos.crop_specie_edicode
        potential_natures = MasterProductionNature.where(agroedi_crop_code: specie_code)
        if potential_natures.count > 1
          @production_nature = potential_natures
            .find_by(specie: ActivityProduction.where(support_id: cap_support_ids)
                                               .joins(:activity)
                                               .select('activities.cultivation_variety'))
        end
        @production_nature ||= potential_natures.first
      end

      def campaign
        return @campaign if @campaign

        campaign = Campaign.find_by(harvest_year: daplos.harvest_year.to_i)
        raise "No campaign for year #{daplos.harvest_year.inspect}" unless campaign

        @campaign = campaign
      end

      def activity_production
        return @activity_production if @activity_production

        production = guess_production_from_islet ||
                     guess_production_from_specie_and_area

        raise "Couldn't find production for Crop #{self.inspect}" unless production

        @activity_production = production
      end
      alias_method :production, :activity_production

      def production_support
        return @production_support if @production_support

        @production_support = activity_production&.support
      end

      def inspect
        pretty_class = self.class.name.split('::').last
        "#{pretty_class}#<parent: DaplosExchanger line: #{daplos_line.inspect}>"
      end

      private

        def align_activity_production_dates!
          return unless production
          return unless started_on && stopped_on

          # update started_on and stopped_on if present on crop in file
          production.started_on = started_on if started_on < production.started_on
          production.stopped_on = stopped_on+1 if stopped_on > production.stopped_on
          production.save!
          production.reload
        end

        def cap_support_ids
          islet_number = daplos.cap_islet_number
          return unless islet_number

          # Finding several islets in case of several Cap statements
          islets = CapIslet.of_campaign(campaign)
                          .where(islet_number: islet_number)
          return unless islets.any?

          islets.joins(:land_parcels).select("#{CapLandParcel.table_name}.support_id")
        end

        def guess_production_from_islet
          return unless cap_support_ids.any?

          ActivityProduction.of_campaign(campaign)
                            .with_cultivation_variety(production_nature.specie)
                            .where(id: cap_support_ids).first
        end

        def guess_production_from_specie_and_area
          crop_area = daplos.crop_areas.first.area_nature_value_in_hectare.to_f
          max_area = crop_area + (crop_area * 0.02)
          min_area = crop_area - (crop_area * 0.50)

          ActivityProduction
            .with_cultivation_variety(production_nature.specie)
            .of_campaign(campaign)
            .where('size_value <= ?', max_area)
            .where('size_value >= ?', min_area)
            .first
        end
    end
  end
end
