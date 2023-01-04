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

      # return MasterCropProduction
      def production_nature

        # return if already set
        return @production_nature if @production_nature

        specie_code = daplos.crop_specie_edicode
        # try on MasterCropProduction uniq reference of agroedi_crop_code
        potential_natures = MasterCropProduction.where(agroedi_crop_code: specie_code)
        # try on full dictionnary of agroedi_crop_code
        unless potential_natures.any?
          crop_reference = RegisteredAgroediCode.of_ekylibre_codes('MasterCropProduction', specie_code).pluck(:ekylibre_value).compact.uniq
          potential_natures = MasterCropProduction.of_reference_names(crop_reference) if crop_reference.any?
        end

        raise "No MasterCropProduction found for #{specie_code}" unless potential_natures.any?

        # if cap_support_ids, try to filter by cultivation_variety
        if potential_natures.any? && cap_support_ids.any?
          @production_nature = potential_natures
            .find_by(specie: ActivityProduction.where(support_id: cap_support_ids)
                                               .joins(:activity)
                                               .select('activities.cultivation_variety'))
        end
        @production_nature ||= potential_natures.first
      end

      def campaign
        return @campaign if @campaign

        campaign = Campaign.of(daplos.harvest_year.to_i)
        raise "No campaign for year #{daplos.harvest_year.inspect}" unless campaign

        @campaign = campaign
      end

      def activity_production
        return @activity_production if @activity_production

        production = guess_production_from_islet ||
                     guess_production_from_specie_and_area

        production ||= create_activity_production

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
          return [] unless islet_number

          # Finding several islets in case of several Cap statements
          islets = CapIslet.of_campaign(campaign)
                          .where(islet_number: islet_number)
          return [] unless islets.any?

          islets.joins(:land_parcels).select("#{CapLandParcel.table_name}.support_id")
        end

        def guess_production_from_islet
          return unless cap_support_ids.any?

          ActivityProduction.of_campaign(campaign)
                            .with_cultivation_variety(production_nature.specie)
                            .where(id: cap_support_ids)
                            .first
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

        def create_activity_production
          if production_nature && campaign && build_shape
            activity = find_or_create_activity
            zc = find_or_create_cultivable_zone
            shape = build_shape
            productions = activity.productions.of_campaign(campaign).support_shape_matching(shape, 0.02)
            if productions.any?
              activity_production = productions.first
            else
              activity_production = activity.productions.new(campaign: campaign)

              activity_production.support_shape = shape
              activity_production.support_nature = :cultivation
              activity_production.cultivable_zone = zc
              activity_production.usage = production_nature.usage
              activity_production.reference_name = production_nature.reference_name

              activity_production.started_on = production_nature.start_on(campaign.harvest_year)
              activity_production.stopped_on = production_nature.stop_on(campaign.harvest_year) if activity.production_cycle == :annual
              activity_production.save!
            end
            activity_production
          else
            raise "Couldn't build activity production for Crop #{self.inspect}"
          end
        end

        def find_or_create_activity
          # find annual or perennial activity
          if production_nature.life_duration.present? && production_nature.life_duration.parts[:years].to_d > 1.0
            production_cycle = :perennial
          else
            production_cycle = :annual
          end

          family_found = Activity.find_best_family(production_nature.specie)

          support_nature = :cultivation

          attributes = {
            cultivation_variety: production_nature.specie,
            name: production_nature.translation.send(Preference[:language]),
            reference_name: production_nature.reference_name,
            production_system_name: "intensive_farming",
            support_variety: :land_parcel,
          }

          # avoid activity_production creation for border, buffer and none
          activity = Activity.find_by(attributes)
          activity ||= Activity.find_by(name: attributes[:name])

          if activity.nil?
            if production_cycle == :annual
              attributes.update(
                family: family_found.name,
                nature: :main,
                production_cycle: production_cycle,
                size_indicator: 'net_surface_area',
                size_unit: 'hectare',
                with_cultivation: true,
                with_supports: true,
                life_duration: 1,
                production_started_on: production_nature.start_on(campaign.harvest_year).change(year: 2000),
                production_stopped_on: production_nature.stop_on(campaign.harvest_year).change(year: 2000),
                production_started_on_year: production_nature.started_on_year,
                production_stopped_on_year: production_nature.stopped_on_year
              )
            elsif production_cycle == :perennial
              attributes.update(
                family: family_found.name,
                nature: :main,
                production_cycle: production_cycle,
                size_indicator: 'net_surface_area',
                size_unit: 'hectare',
                with_cultivation: true,
                with_supports: true,
                life_duration: production_nature.life_duration.parts[:years].to_d,
                start_state_of_production_year: 2,
                production_started_on: production_nature.start_on(campaign.harvest_year).change(year: 2000),
                production_stopped_on: production_nature.stop_on(campaign.harvest_year).change(year: 2000),
                production_started_on_year: production_nature.started_on_year,
                production_stopped_on_year: production_nature.stopped_on_year
              )
            end
            activity = Activity.create!(attributes)
          end
          activity
        end

        def find_or_create_cultivable_zone
          # check if existing CultivableZone cover, overlap or intersect a crop shape
          shape = build_shape
          # info = c.to_ewkt[0..100] + "...\n"
          crop_inside_cultivable_zone = CultivableZone.shape_covering(shape, 0.05)
          unless crop_inside_cultivable_zone.any?
            # info << "Overlaps!\n"
            crop_inside_cultivable_zone = CultivableZone.shape_matching(shape, 0.10)
            crop_inside_cultivable_zone ||= CultivableZone.shape_intersecting(shape, 0.02)
          end

          # find or create a CultivableZone according to islet link to crop
          if crop_inside_cultivable_zone.any?
            cultivable_zone = crop_inside_cultivable_zone.first
          else
            number = 'ZC#' + format('%02d', daplos.land_parcel_work_number.to_s)
            cultivable_zone = CultivableZone.find_or_initialize_by(work_number: number)
            cultivable_zone.name ||= daplos.crop_name_details + ' ' + daplos.cap_islet_number
            cultivable_zone.shape ||= shape
            cultivable_zone.save!
          end
          cultivable_zone
        end

        # return polygon shape in 4326 from multi-points in 27572 or 4326
        def build_shape
          if daplos.crop_areas&.first
            c_area = daplos.crop_areas.first
            if c_area.crop_spatial_coordinates.any?
              srs = c_area.crop_spatial_coordinates.first.srs.strip
              if srs == '3'
                srid = 27_572
              elsif srs == '4'
                srid = 4326
              elsif srs == '5'
                srid = 2154
              end
              # build factory from source srid
              factory = ::Charta::Geometry.factory(srid)
              points = []
              # compute points from lat / lon
              c_area.crop_spatial_coordinates.each do |p|
                points << factory.point(p.latitude.to_f, p.longitude.to_f)
              end
              # build linear_ring
              outerring = factory.linear_ring(points)
              # build polygon from linear_ring as outer ring (exterior ring)
              square = factory.polygon(outerring)
              # convert from source srid to 4326 and fix is simple if needed
              shape = transform_geometry(square, srid)
            else
              nil
            end
          else
            nil
          end
        end

        def shape_corrector
          @shape_corrector ||= ShapeCorrector.build
        end

        def transform_geometry(geometry, srid)
          geom = ::Charta.new_geometry(geometry, srid).transform(:WGS84)
          if !geom.simple?
            corrected_geom = shape_corrector.try_fix(geom)
            raise StandardError.new('Invalid geometry') if !corrected_geom.simple?

            geom = corrected_geom.or_raise
          end
          geom
        end

    end
  end
end
