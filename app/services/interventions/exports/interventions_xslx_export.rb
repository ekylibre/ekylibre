# frozen_string_literal: true

module Interventions
  module Exports
    class InterventionsXslxExport
      include Rails.application.routes.url_helpers
      def generate(activity_id: nil, activity_production_id: nil, land_parcel_id: nil, plant_id: nil, campaign_ids: nil, with_land_parcel_interventions_on_plant: false)

        # we want only intervention related to plant farming but no sowing in plant/land_parcel case to avoid double
        activity_family = :plant_farming
        plant_farming_procedures = Procedo::Procedure.of_activity_family(activity_family)
        sowing_procedures = Procedo::Procedure.of_category(:planting)
        plant_farming_without_sowing_procedures = plant_farming_procedures - sowing_procedures

        # procedures filters
        @plant_farming_procedures_filter = plant_farming_procedures.map { |p| p.name.to_s.inspect }.join(", ").tr('"', "'")
        @plant_farming_without_sowing_procedures_filter = plant_farming_without_sowing_procedures.map { |p| p.name.to_s.inspect }.join(", ").tr('"', "'")

        sql = <<~SQL
          SELECT
            a.name as activity_name,
            a.production_system_name as activity_system_name,
            sp.name as land_parcel_name,
            p.id as target_product_id,
            p.name as plant_name,
            sowing_output.batch_number as plant_batch_number,
            sowing_output.specie_variety->>'name' as plant_variety,
            CASE
		          WHEN it.working_zone_area_value IS NULL THEN it.quantity_population
		          WHEN it.working_zone_area_value IS NOT NULL THEN it.working_zone_area_value
		          ELSE NULL END AS working_area,
            ap.size_value as surface_area,
            (SELECT (ST_Area(pr.multi_polygon_value, true) / 10000) FROM product_readings pr WHERE pr.product_id = p.id AND indicator_name = 'shape' ORDER BY pr.read_at DESC LIMIT 1) as target_surface_area,
            a.cultivation_variety as cultivation_variety,
            i.procedure_name as procedure_name,
            i.id as intervention_id,
            i.number as intervention_number,
            i.custom_fields->>'justification_traitement' as justification_traitement,
            i.state,
            i.started_at as started_at,
            pinput.name as input_name,
            input.quantity_value as input_quantity,
            input.quantity_unit_name as input_quantity_unit,
            input_variant.france_maaid,
            phyto.name as phyto_name,
            phyto.active_compounds as active_compounds,
            phyto.allowed_mentions->>'organic_usage' as organic_usage,
            phyto.allowed_mentions->>'biocontrole_usage' as biocontrole_usage,
            phyto.in_field_reentry_delay,
            TO_CHAR(phyto.in_field_reentry_delay, 'HH24') AS reentry_delay_in_hour,
            i.started_at + phyto.in_field_reentry_delay AS min_date_to_reenter,
            phyto_usage.ephy_usage_phrase as phyto_usage,
            phyto_usage.species,
            CASE WHEN phyto_usage.state = 'authorized' THEN 1 ELSE 0 END as phyto_usage_state,
            phyto_usage.dose_quantity as dose_quantity,
            CASE
               WHEN phyto_usage.dose_quantity IS NULL THEN 0
               WHEN input.quantity_value IS NULL THEN 0
            ELSE ROUND((input.quantity_value / phyto_usage.dose_quantity) * 100, 2) END as legal_ratio,
            phyto_usage.dose_unit_name as dose_unit,
            phyto_usage.pre_harvest_delay,
            TO_CHAR(phyto_usage.pre_harvest_delay, 'DD') AS pre_harvest_delay_in_day,
            i.started_at + phyto_usage.pre_harvest_delay as min_date_to_harvest
          FROM intervention_parameters AS it
          JOIN interventions AS i ON it.intervention_id = i.id
          LEFT JOIN products AS p ON it.product_id = p.id
          LEFT JOIN activity_productions AS ap ON p.activity_production_id = ap.id
          LEFT JOIN products AS sp ON ap.support_id = sp.id
          LEFT JOIN activities AS a ON ap.activity_id = a.id
          LEFT JOIN intervention_parameters AS sowing_output ON sowing_output.product_id = p.id AND sowing_output.reference_name = 'plant' AND sowing_output.type = 'InterventionOutput'
          JOIN intervention_parameters AS input ON input.intervention_id = i.id AND input.type = 'InterventionInput'
          LEFT JOIN products AS pinput ON input.product_id = pinput.id
          LEFT JOIN product_nature_variants AS input_variant ON input.variant_id = input_variant.id
          LEFT JOIN registered_phytosanitary_products AS phyto ON input_variant.reference_name = phyto.reference_name
          LEFT JOIN registered_phytosanitary_usages AS phyto_usage ON phyto.id = phyto_usage.product_id AND input.usage_id = phyto_usage.id
          WHERE i.nature = 'record'
          AND it.reference_name IN ('zone', 'plant', 'land_parcel', 'cultivation')
          #{filter_land_parcel_and_plant(with_land_parcel_interventions_on_plant, land_parcel_id, plant_id)}
          #{filter_campaign(campaign_ids)}
          #{filter_activity(activity_id)}
          #{filter_activity_production(activity_production_id)}
          ORDER BY a.name, sp.name, i.started_at ASC
        SQL

        generate_ods(ApplicationRecord.connection.execute(sql))
      end

      private

        def filter_activity(activity_id)
          if activity_id.present?
            "AND a.id = #{activity_id}"
          else
            ''
          end
        end

        def filter_campaign(campaign_ids)
          if campaign_ids.present?
            "AND i.id IN (SELECT intervention_id FROM campaigns_interventions WHERE campaign_id IN (#{campaign_ids.join(',')}))"
          else
            ''
          end
        end

        # use for both intervention where land_parcel or plant is target by the activity production
        def filter_activity_production(activity_production_id)
          if activity_production_id.present?
            "AND ap.id = #{activity_production_id}"
          else
            ''
          end
        end

        # use for filtering plant intervention and land_parcel interventions as well
        def filter_land_parcel_and_plant(with_land_parcel_interventions_on_plant, land_parcel_id, plant_id)
          if with_land_parcel_interventions_on_plant && land_parcel_id.present? && plant_id.present?
            filter = "AND ((it.type IN ('InterventionTarget', 'InterventionOutput') AND p.id = #{plant_id} AND i.procedure_name IN (#{@plant_farming_procedures_filter}))"
            filter << " OR (it.type IN ('InterventionTarget') AND p.id = #{land_parcel_id} AND i.procedure_name IN (#{@plant_farming_without_sowing_procedures_filter})))"
          # case land_parcel or activity production controller
          # all target with all plant farming procedure
          elsif !with_land_parcel_interventions_on_plant && plant_id.present?
            "AND it.type IN ('InterventionTarget', 'InterventionOutput') AND i.procedure_name IN (#{@plant_farming_procedures_filter}) AND AND p.id = #{plant_id}"
          elsif !with_land_parcel_interventions_on_plant && land_parcel_id.present?
            "AND it.type IN ('InterventionTarget') AND i.procedure_name IN (#{@plant_farming_procedures_filter}) AND AND p.id = #{land_parcel_id}"
          # case land_parcel or activity production controller
          # all target with all plant farming procedure
          else
            "AND it.type IN ('InterventionTarget') AND i.procedure_name IN (#{@plant_farming_procedures_filter})"
          end
        end

        def generate_ods(dataset)
          require 'axlsx'
          p = Axlsx::Package.new
          wb = p.workbook

          s = wb.styles
          header_style = s.add_style sz: 12, b: true, alignment: { horizontal: :center }, font_name: 'Arial'
          row_style = s.add_style sz: 10, alignment: { horizontal: :center }, font_name: 'Arial'
          legal_ratio_style = s.add_style bg_color: 'FF428751', type: :dxf
          autorized_style = s.add_style bg_color: '00ff04', type: :dxf
          date_style = s.add_style format_code: 'dd/mm/yyyy'
          hour_style = s.add_style format_code: 'dd/mm/yyyy hh:mm'

          headers = []
          headers << :date.tl
          headers << :activity.tl
          headers << Activity.human_attribute_name(:production_system_name)
          headers << :land_parcel_name.tl
          headers << :plant.tl
          headers << InterventionOutput.human_attribute_name(:batch_number)
          headers << Activity.human_attribute_name(:cultivation_variety)
          headers << :total_net_surface_area.tl
          headers << :working_area.tl
          headers << Intervention.human_attribute_name(:procedure_name)
          headers << :inputs.tl
          headers << InterventionInput.human_attribute_name(:quantity)
          headers << InterventionInput.human_attribute_name(:quantity_unit)
          headers << :france_maaid.tl
          headers << :active_compounds.tl
          headers << :phytosanitary_treatment_informations.tl
          headers << :reentry_delay_in_hour.tl
          headers << :minimum_date_to_reenter_in_land_parcel.tl
          headers << :pre_harvest_delay_in_day.tl
          headers << :minimum_date_to_harvest_land_parcel.tl
          headers << :link.tl

          wb.add_worksheet(name: :interventions.tl) do |sheet|
            # add header
            sheet.add_row headers, style: [header_style] * headers.count
            # add lines
            dataset.each_with_index do |item, index|
              line = item.to_struct
              plant_presence = Product.find(line.target_product_id).is_a?(Plant)
              intervention_url = "https://#{Ekylibre::Tenant.host}" + backend_intervention_path(line.intervention_id)
              detail = []
              detail_style = []
              detail << Date.parse(line.started_at)
              detail_style << date_style
              detail << line.activity_name
              detail_style << row_style
              detail << (line.activity_system_name.presence ? Onoma::ProductionSystem[line.activity_system_name].l : nil)
              detail_style << row_style
              detail << line.land_parcel_name
              detail_style << row_style
              detail << (plant_presence ? line.plant_name : nil)
              detail_style << row_style
              detail << (plant_presence ? line.plant_batch_number : nil)
              detail_style << row_style
              detail << (plant_presence ? line.plant_variety : nil)
              detail_style << row_style
              detail << line.target_surface_area.to_d.round(2)
              detail_style << row_style
              detail << line.working_area.to_d.round(2)
              detail_style << row_style
              detail << I18n.t(line.procedure_name, scope: 'procedures')
              detail_style << row_style
              detail << line.input_name
              detail_style << row_style
              detail << line.input_quantity
              detail_style << row_style
              detail << (line.input_quantity_unit.presence && Onoma::Unit[line.input_quantity_unit.to_sym].present? ? Onoma::Unit[line.input_quantity_unit.to_sym].symbol : line.input_quantity_unit )
              detail_style << row_style
              detail << line.france_maaid
              detail_style << row_style
              detail << line.active_compounds
              detail_style << row_style
              detail << (line.phyto_usage.blank? ? line.justification_traitement : line.phyto_usage)
              detail_style << row_style
              detail << line.reentry_delay_in_hour
              detail_style << row_style
              detail << (line.min_date_to_reenter.presence ? Time.parse(line.min_date_to_reenter) : '')
              detail_style << hour_style
              detail << line.pre_harvest_delay_in_day
              detail_style << row_style
              detail << (line.min_date_to_harvest.presence ? Date.parse(line.min_date_to_harvest) : '')
              detail_style << date_style
              detail << line.intervention_id
              detail_style << row_style

              sheet.add_row detail, style: detail_style
              sheet.add_hyperlink location: intervention_url, ref: "U#{index + 2}"
            end
          end
          p.to_stream
        end
    end
  end
end
