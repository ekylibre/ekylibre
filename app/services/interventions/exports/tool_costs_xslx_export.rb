# frozen_string_literal: true

module Interventions
  module Exports
    class ToolCostsXslxExport
      include Rails.application.routes.url_helpers
      def generate(activity_id: nil, equipment_ids: nil, campaign_ids: nil)

        activity_production_ids = ActivityProduction.of_campaign(campaign_ids).of_activity(activity_id).pluck(:id) if activity_id.present? && campaign_ids.present?

        sql = <<~SQL
          SELECT
            p.name as product_name,
            pnv.name,
            pn.name AS equipment_nature ,
            i.started_at AS started_at,
            i.procedure_name AS procedure_name,
            i.working_duration / 3600.0 AS intervention_duration,
            i.number AS intervention_number,
            (SELECT SUM(ST_Area(ipt.working_zone, true) / 10000) FROM intervention_parameters AS ipt WHERE ipt.intervention_id = i.id AND ipt.type = 'InterventionTarget' AND ipt.reference_name IN ('land_parcel', 'cultivation', 'plant', 'zone')) AS intervention_working_area,
            i.id AS intervention_id,
            (SELECT SUM(iwp.duration / 3600.0)
            FROM intervention_working_periods AS iwp
            WHERE iwp.intervention_participation_id IN (SELECT ip.id FROM intervention_participations AS ip WHERE ip.product_id = p.id AND ip.intervention_id = i.id)
            AND iwp.nature = 'intervention'
            ) AS equipement_intervention_duration,
            (SELECT SUM(iwp.duration / 3600.0)
            FROM intervention_working_periods AS iwp
            WHERE iwp.intervention_participation_id IN (SELECT ip.id FROM intervention_participations AS ip WHERE ip.product_id = p.id AND ip.intervention_id = i.id)
            AND iwp.nature = 'travel'
            ) AS equipement_travel_duration,
            (SELECT MAX(amount) FROM catalog_items AS ci WHERE ci.variant_id = pnv.id AND ci.catalog_id = (SELECT c.id FROM catalogs AS c WHERE c.usage = 'cost')) AS unit_price_intervention,
            (SELECT MAX(amount) FROM catalog_items AS ci WHERE ci.variant_id = pnv.id AND ci.catalog_id = (SELECT c.id FROM catalogs AS c WHERE c.usage = 'travel_cost')) AS unit_price_travel
          FROM intervention_parameters AS it
            JOIN interventions AS i ON it.intervention_id = i.id
            LEFT JOIN products AS p ON it.product_id = p.id
            JOIN product_nature_variants AS pnv ON pnv.id = p.variant_id
            JOIN product_natures AS pn ON pn.id = p.nature_id
          WHERE it.type IN ('InterventionTool') AND i.nature = 'record'
            #{filter_equipment(equipment_ids)}
            #{filter_campaign(campaign_ids)}
          ORDER BY i.started_at, p.name ASC
        SQL

        request = ApplicationRecord.connection.execute(sql)

        generate_ods(request)
      end

      private

        def filter_equipment(equipment_ids)
          if equipment_ids.present?
            "AND p.id IN (#{equipment_ids.join(',')})"
          else
            ''
          end
        end

        def filter_campaign(campaign_ids)
          campaign_harvest_years = Campaign.where(id: campaign_ids).pluck(:harvest_year) if campaign_ids.any?
          if campaign_harvest_years.any?
            "AND EXTRACT(YEAR FROM i.started_at) IN (#{campaign_harvest_years.join(',')})"
          else
            ''
          end
        end

        def generate_ods(dataset)
          require 'axlsx'
          p = Axlsx::Package.new
          wb = p.workbook

          s = wb.styles
          header_style = s.add_style sz: 12, b: true, alignment: { horizontal: :center }, font_name: 'Arial'
          row_style = s.add_style sz: 10, alignment: { horizontal: :center }, font_name: 'Arial'
          formula_style = s.add_style sz: 12, b: true, alignment: { horizontal: :center }, font_name: 'Arial'
          legal_ratio_style = s.add_style bg_color: '43AAFF', type: :dxf
          total_cost_ratio_style = s.add_style bg_color: 'FFAC43', type: :dxf
          date_style = s.add_style format_code: 'dd/mm/yyyy'
          # autorized_style = s.add_style bg_color: '00ff04', type: :dxf

          # Worksheet Interventions
          headers = []
          headers << :date.tl
          headers << Intervention.human_attribute_name(:procedure_name)
          headers << :equipment_nature.tl
          headers << :working_area_in_hectare.tl
          headers << :working_duration_in_hour.tl
          headers << :detail_working_intervention_duration.tl
          headers << :detail_travel_intervention_duration.tl
          headers << :intervention_unit_pretax_amount.tl
          headers << :intervention_travel_unit_pretax_amount.tl
          headers << :total_cost.tl
          headers << :working_hectare_costs.tl
          headers << :link.tl

          wb.add_worksheet(name: :interventions_costs.tl) do |sheet|
            # add header
            sheet.add_row headers, style: [header_style] * headers.count
            # add lines
            total_working_area = []
            total_intervention_duration = []
            total_equipement_intervention_duration = []
            total_equipement_travel_duration = []
            dataset.each_with_index do |item, index|
              line = item.to_struct
              intervention_url = "https://#{Ekylibre::Tenant.host}" + backend_intervention_path(line.intervention_id)
              total_costs = ((line.equipement_travel_duration.presence || line.equipement_intervention_duration.presence) ? (line.equipement_travel_duration.to_d * line.unit_price_travel.to_d) + (line.equipement_intervention_duration.to_d * line.unit_price_intervention.to_d) : line.intervention_duration.to_d * line.unit_price_intervention.to_d)
              working_area_costs = (line.intervention_working_area.to_d > 0.0 ? (total_costs.to_d / line.intervention_working_area.to_d) : nil)
              detail = []
              detail_style = []
              detail << Date.parse(line.started_at)
              detail_style << date_style
              detail << I18n.t(line.procedure_name, scope: 'procedures')
              detail_style << row_style
              detail << line.equipment_nature
              detail_style << row_style
              detail << line.intervention_working_area.to_d.round(2)
              detail_style << row_style
              total_working_area << line.intervention_working_area.to_d.round(2)
              detail << line.intervention_duration.to_d.round(2)
              detail_style << row_style
              total_intervention_duration << line.intervention_duration.to_d.round(2)
              detail << line.equipement_intervention_duration.to_d.round(2)
              detail_style << row_style
              total_equipement_intervention_duration << line.equipement_intervention_duration.to_d.round(2)
              detail << line.equipement_travel_duration.to_d.round(2)
              detail_style << row_style
              total_equipement_travel_duration << line.equipement_travel_duration.to_d.round(2)
              detail << line.unit_price_intervention.to_d.round(2)
              detail_style << row_style
              detail << line.unit_price_travel.to_d.round(2)
              detail_style << row_style
              detail << total_costs.to_d.round(2)
              detail_style << row_style
              detail << working_area_costs.to_d.round(2)
              detail_style << row_style
              detail << line.intervention_number
              detail_style << row_style

              sheet.add_row detail, style: detail_style
              sheet.add_hyperlink location: intervention_url, ref: "L#{index + 2}"
            end
            # add sum formula
            bottom_formula = []
            bottom_formula << :totals.tl
            bottom_formula << ''
            bottom_formula << ''
            bottom_formula << total_working_area.compact.sum
            bottom_formula << total_intervention_duration.compact.sum
            bottom_formula << total_equipement_intervention_duration.compact.sum
            bottom_formula << total_equipement_travel_duration.compact.sum
            bottom_formula << ''
            bottom_formula << ''
            bottom_formula << ''

            sheet.add_row bottom_formula, style: [formula_style] * headers.count

            # add progress bar on costs
            data_bar = Axlsx::DataBar.new
            sheet.add_conditional_formatting("J2:J#{dataset.count + 1}",
                                             type: :dataBar,
                                             dxfId: legal_ratio_style,
                                             priority: 1,
                                             data_bar: data_bar)
            sheet.add_conditional_formatting("K2:K#{dataset.count + 1}",
                                             type: :dataBar,
                                             dxfId: legal_ratio_style,
                                             priority: 1,
                                             data_bar: data_bar)

          end

          p.to_stream
        end
    end
  end
end
