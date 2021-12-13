# frozen_string_literal: true

module Telepac
  module ExchangerMixin
    extend ActiveSupport::Concern

    IGNORED = %w[BFP BFS BOR BTA MRS SNE].freeze
    FALLOW_LAND = %w[J5M J6S J6P JNO].freeze

    module ClassMethods
      def campaign(campaign = nil)
        if campaign.nil?
          @campaign
        else
          @campaign = campaign
        end
      end
    end

    included do
      category :plant_farming
      vendor :telepac
    end

    def check
      # check if file is a valid XML
      Nokogiri::XML(File.open(file), &:noblanks)

      true
    end

    def import
      # import and parse file
      doc = Nokogiri::XML(File.open(file)) do |config|
        config.strict.nonet.noblanks
      end

      w.count = doc.css('parcelle').count

      # get pacage number and campaign
      pacage_number = doc.at_css('producteur').attribute('numero-pacage').value

      campaign = Campaign.find_or_create_by!(harvest_year: self.class.campaign)

      # get the exploitation siret_number
      siret_number = doc.at_css('demandeur siret').text

      # get global SRID
      first_town = doc.at_css('commune').text
      global_srid = find_srid(first_town)

      # get the exploitation name
      farm_name = guess_exploitation_name(doc)

      ## find or create Entity
      declarant = Entity.find_by('last_name ILIKE ?', farm_name)
      if declarant.nil?
        country_preference = Preference[:country]
        declarant = Entity.create!(
          last_name: farm_name,
          active: true,
          nature: :organization,
          country: country_preference,
          siret_number: siret_number
        )
      end

      cap_statement = CapStatement
                        .create_with(
                          farm_name: farm_name,
                        )
                        .find_or_create_by(
                          campaign: campaign,
                          declarant: declarant,
                          pacage_number: pacage_number,
                          siret_number: siret_number,
                        )

      # get the islets
      handle_islet(cap_statement, doc)

      # get SNA
      handle_sna(cap_statement, doc, global_srid)

      true
    end

    private

      def create_activity_production(cap_land_parcel, cap_year:, is_organic:)

        crop_code = cap_land_parcel.main_crop_code

        return nil if IGNORED.include?(crop_code.to_s)

        # check in Lexicon
        cap_year = [2017, cap_year].max
        lexicon_production_nature = MasterCropProduction.joins(:cap_codes)
                                                        .where('master_crop_production_cap_codes.cap_code = ? AND master_crop_production_cap_codes.year = ?', crop_code, cap_year).first
        raise StandardError.new("The code #{crop_code} was not found in the lexicon") if lexicon_production_nature.nil?

        # find annual or perennial activity
        if lexicon_production_nature.life_duration.present? && lexicon_production_nature.life_duration.parts[:years].to_d > 1.0
          production_cycle = :perennial
        else
          production_cycle = :annual
        end

        family_found = Activity.find_best_family(lexicon_production_nature.specie)

        support_nature = FALLOW_LAND.include?(crop_code.to_s) ? :fallow_land : :cultivation

        attributes = {
          cultivation_variety: lexicon_production_nature.specie,
          name: lexicon_production_nature.translation.send(Preference[:language]),
          reference_name: lexicon_production_nature.reference_name,
          production_system_name: (is_organic == 'true' ? "organic_farming" : "intensive_farming"),
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
              production_started_on: lexicon_production_nature.start_on(cap_year).change(year: 2000),
              production_stopped_on: lexicon_production_nature.stop_on(cap_year).change(year: 2000),
              production_started_on_year: lexicon_production_nature.started_on_year,
              production_stopped_on_year: lexicon_production_nature.stopped_on_year
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
              life_duration: lexicon_production_nature.life_duration.parts[:years].to_d,
              start_state_of_production_year: 2,
              production_started_on: lexicon_production_nature.start_on(cap_year).change(year: 2000),
              production_stopped_on: lexicon_production_nature.stop_on(cap_year).change(year: 2000),
              production_started_on_year: lexicon_production_nature.started_on_year,
              production_stopped_on_year: lexicon_production_nature.stopped_on_year
            )
          end

          activity = Activity.create!(attributes)
        end

        # check if existing CultivableZone cover, overlap or intersect a cap_land_parcel
        cap_islet_shape = ::Charta.new_geometry(cap_land_parcel.islet.shape)
        cap_land_parcel_shape = ::Charta.new_geometry(cap_land_parcel.shape)
        # info = c.to_ewkt[0..100] + "...\n"
        cap_land_parcel_inside_cultivable_zone = CultivableZone.shape_covering(cap_land_parcel_shape, 0.05)
        unless cap_land_parcel_inside_cultivable_zone.any?
          # info << "Overlaps!\n"
          cap_land_parcel_inside_cultivable_zone = CultivableZone.shape_matching(cap_land_parcel_shape, 0.10)
          cap_land_parcel_inside_cultivable_zone ||= CultivableZone.shape_intersecting(cap_land_parcel_shape, 0.02)
        end

        # find or create a CultivableZone according to islet link to cap_land_parcel
        # TODO check correctly if cap_land_parcel is inside a cultivable_zone
        if cap_land_parcel_inside_cultivable_zone.any?
          # info << "Found\n"
          cultivable_zone = cap_land_parcel_inside_cultivable_zone.first
        else
          number = 'ZC#' + format('%02d', cap_land_parcel.islet_number.to_s)
          cultivable_zone = CultivableZone.find_or_initialize_by(work_number: number)
          cultivable_zone.name ||= cap_land_parcel.islet.city_name + " #" + format('%02d', cap_land_parcel.islet_number.to_s)
          cultivable_zone.shape ||= cap_islet_shape
          cultivable_zone.save!
        end

        # find or create an activity_production according to current informations
        # FIXME find_by_shape doesn't work...
        campaign = Campaign.find_or_create_by!(harvest_year: cap_year)
        productions = activity.productions.of_campaign(campaign).support_shape_matching(cap_land_parcel_shape, 0.02)

        if productions.any?
          activity_production = productions.first
        else
          activity_production = activity.productions.new(campaign: campaign)

          activity_production.support_shape = cap_land_parcel_shape
          activity_production.support_nature = support_nature
          activity_production.cultivable_zone = cultivable_zone
          activity_production.usage = lexicon_production_nature.usage
          activity_production.reference_name = lexicon_production_nature.reference_name

          activity_production.started_on = lexicon_production_nature.start_on(cap_year)
          activity_production.stopped_on = lexicon_production_nature.stop_on(cap_year) if production_cycle == :annual
          activity_production.save!
        end

        # link cap_land_parcel and activity_production
        cap_land_parcel.activity_production = activity_production
        cap_land_parcel.save!
      end

      # @param [String] insee_code
      # @return [Numeric]
      def find_srid(insee_code)
        dep = insee_code[0..2].to_s

        if dep == "976"
          2980
        else
          2154
        end
      end

      def guess_exploitation_name(doc)
        if (exploitation_nature = doc.at_css('identification-societe exploitation'))
          exploitation_nature.text
        elsif (exploitation_nature = doc.at_css('identification-individuelle identite'))
          exploitation_nature.text
        else
          raise "No farm name found in TelePAC folder."
        end
      end

      def shape_corrector
        @shape_corrector ||= ShapeCorrector.build
      end

      def transform_geometry(geometry, srid)
        geom = ::Charta.from_gml(geometry, srid).transform(:WGS84)
        if !geom.is_simple?
          corrected_geom = shape_corrector.try_fix(geom)
          raise StandardError.new('Invalid geometry') if !corrected_geom.is_simple?

          geom = corrected_geom.or_raise
        end
        geom
      end

      def handle_islet(cap_statement, doc)
        doc.css('ilot').each do |islet|
          # get islet attributes
          # islet number and town_number
          islet_number = islet.attribute('numero-ilot').value
          town_number = islet.css('commune').text
          srid = find_srid(town_number)

          # islet shape, validate GML and transform into Charta
          geometry = islet.xpath('.//gml:Polygon')
          geometry.first['srsName'] = "EPSG:#{srid}"
          geom = transform_geometry(geometry.first.to_xml.to_s.squish, srid).convert_to(:multi_polygon)

          islet_attributes = {
            cap_statement: cap_statement,
            islet_number: islet_number,
            town_number: town_number,
            shape: geom.to_rgeo
          }

          # find and update or create islet according to cap statement
          cap_islet = CapIslet.find_by(islet_attributes.slice(:islet_number, :cap_statement))
          cap_islet ||= CapIslet.new
          cap_islet.attributes = islet_attributes
          cap_islet.save!

          # import into georeadings
          label = 'I' + '-' + cap_islet.cap_statement.pacage_number.to_s + '-' + cap_islet.cap_statement.campaign.harvest_year.to_s + '-' + cap_islet.islet_number.to_s
          ensure_georeading(label, cap_islet.shape)

          # get cap_land_parcels
          handle_landparcels(cap_islet, islet, srid)
        end
      end

      def handle_landparcels(cap_islet, islet, srid)
        islet.css('parcelle').each do |land_parcel|
          # get land_parcel attributes
          land_parcel_number = land_parcel.css('descriptif-parcelle').attribute('numero-parcelle').value
          main_crop_seed_production = land_parcel.css('culture-principale').attribute('production-semences').value

          commercialisation = land_parcel.css('culture-principale').attribute('commercialisation')
          organic = land_parcel.css('agri-bio').attribute('conduite-bio')
          main_crop_commercialisation = if commercialisation.present?
                                          commercialisation.value
                                        else
                                          false
                                        end
          is_organic = if organic.present?
                         organic.value
                       else
                         false
                       end

          main_crop_code = land_parcel.css('culture-principale > code-culture').text
          main_crop_precision = land_parcel.css('precision').text

          # land_parcel shape, validate GML and transform into Charta
          geometry = land_parcel.xpath('.//gml:Polygon')
          geometry.first['srsName'] = "EPSG:#{srid}"
          geom = transform_geometry(geometry.first.to_xml.to_s.squish, srid).convert_to(:multi_polygon)

          cap_land_parcel_attributes = {
            cap_islet: cap_islet,
            land_parcel_number: land_parcel_number,
            main_crop_code: main_crop_code,
            main_crop_commercialisation: main_crop_commercialisation,
            main_crop_precision: main_crop_precision,
            main_crop_seed_production: main_crop_seed_production,
            shape: geom.to_rgeo
          }

          # find and update or create land_parcel according to cap statement and islet
          if (cap_land_parcel = CapLandParcel.find_by(cap_land_parcel_attributes.slice(:land_parcel_number, :cap_islet)))
            cap_land_parcel.update_attributes!(cap_land_parcel_attributes)
          else
            cap_land_parcel = CapLandParcel.create!(cap_land_parcel_attributes)
          end

          # import into georeadings
          label = 'P' + '-' + cap_land_parcel.islet.cap_statement.pacage_number.to_s + '-' + cap_land_parcel.cap_islet.cap_statement.campaign.harvest_year.to_s + '-' + cap_land_parcel.islet_number.to_s + '-' + cap_land_parcel.land_parcel_number.to_s
          ensure_georeading(label, cap_land_parcel.shape)

          create_activity_production(cap_land_parcel, cap_year: self.class.campaign, is_organic: is_organic)

          w.check_point
        end
      end

      def ensure_georeading(label, shape)
        Georeading
          .create_with(
            name: label,
            nature: :polygon,
            content: shape
          )
          .find_or_create_by(
            number: label
          )
      end

      def handle_sna(cap_statement, doc, global_srid)
        doc.css('sna-declaree').each do |sna|
          if sna.css('numeroSna').text.blank?
            sna_number = sna.css('numeroSnacreationTas').text
          else
            sna_number = sna.css('numeroSna').text
          end
          sna_category = sna.css('categorieSna').text
          sna_nature = sna.css('typeSna').text

          geometry = sna.xpath('.//gml:Polygon')
          if !geometry.empty?
            geometry.first['srsName'] = "EPSG:#{global_srid}"
            geom = transform_geometry(geometry.first.to_xml.to_s.squish, global_srid).convert_to(:multi_polygon)
          end

          geometry = sna.xpath('.//gml:Point')
          if !geometry.empty?
            geometry.first['srsName'] = "EPSG:#{global_srid}"
            geom = transform_geometry(geometry.first.to_xml.to_s.squish, global_srid).convert_to(:point)
          end

          next if geom.empty?

          cap_neutral_area_attributes = {
            cap_statement_id: cap_statement.id,
            number: sna_number,
            category: sna_category,
            nature: sna_nature,
            shape: geom.to_rgeo
          }

          # find and update or create neutral_area according to cap statement
          if (cap_neutral_area = CapNeutralArea.find_by(cap_neutral_area_attributes.slice(:cap_statement_id, :number)))
            cap_neutral_area.update_attributes!(cap_neutral_area_attributes)
          else
            CapNeutralArea.create!(cap_neutral_area_attributes)
          end
        end
      end

  end
end
