# frozen_string_literal: true

module Interventions
  module Exports
    class GlobalCostsXslxExport
      include Rails.application.routes.url_helpers
      def generate(activity_id: nil, land_parcel_id: nil, plant_id: nil, campaign_ids: nil)

        activity_production_ids = ActivityProduction.of_campaign(campaign_ids).of_activity(activity_id).pluck(:id) if activity_id.present? && campaign_ids.present?

        sql = <<~SQL
          SELECT
            support.name AS activity_production_name,
            ap.id AS activity_production_id,
            ap.size_value AS activity_production_size,
            ap.size_unit_name AS activity_production_size_unit,
            ap.custom_fields->>'objectif_de_cout_ha' as objectif_cost_per_hectare,
            i.procedure_name AS procedure_name,
            i.id AS intervention_id,
            i.number AS intervention_number,
            i.started_at as started_at,
            target_products.name AS target_name,
            target_products.id AS target_product_id,
            CASE target_intervention.working_zone_area_value WHEN NULL THEN NULL ELSE target_intervention.working_zone_area_value END AS target_working_zone,
            apic.inputs AS inputs_costs,
            apic.doers AS doers_costs,
            apic.tools AS tools_costs,
            apic.receptions AS receptions_costs,
            apic.total AS total_costs
          FROM activity_productions AS ap
          JOIN products AS support ON ap.support_id = support.id
          JOIN products AS target_products ON ap.id = target_products.activity_production_id
          JOIN activity_productions_interventions_costs AS apic ON apic.activity_production_id = ap.id AND target_products.id = apic.target_id
          JOIN interventions AS i ON apic.intervention_id = i.id
          JOIN intervention_parameters AS target_intervention ON target_intervention.intervention_id = i.id AND target_intervention.type = 'InterventionTarget' AND target_intervention.product_id = target_products.id
          WHERE ap.support_nature = 'cultivation' AND i.nature = 'record'
          #{filter_activity_production(activity_production_ids)}
          ORDER BY activity_production_name, target_name, started_at ASC
        SQL

        harvest_sql = <<~SQL
          SELECT
            ap.id as activity_production_id,
            support.name as activity_production_name,
            ip_target.imputation_ratio as ratio,
            ip.intervention_id as intervention_id,
            i.started_at as started_at,
            ip.new_name as tracking_name,
            ip.quantity_population as intervention_quantity_population,
            ip.quantity_population * ip_target.imputation_ratio AS target_quantity_population,
            ip_variant.unit_name as variant_unit_name,
            ip.quantity_value as intervention_quantity_value,
            ip.quantity_value * ip_target.imputation_ratio AS target_quantity_value,
            ip.quantity_unit_name as quantity_unit
            FROM intervention_parameters as ip
            JOIN product_nature_variants as ip_variant ON ip_variant.id = ip.variant_id
            JOIN interventions as i on ip.intervention_id = i.id
            JOIN intervention_parameters as ip_target ON i.id = ip_target.intervention_id AND ip_target.type = 'InterventionTarget'
            JOIN products AS p_target ON ip_target.product_id = p_target.id
            JOIN activity_productions AS ap ON p_target.activity_production_id = ap.id
            JOIN products AS support ON support.id = ap.support_id
          WHERE i.procedure_name = 'harvesting' AND ip.type = 'InterventionOutput'
          #{filter_harvest_activity_production(activity_production_ids)}
          ORDER BY activity_production_name
        SQL

        request = ApplicationRecord.connection.execute(sql)
        harvest_request = ApplicationRecord.connection.execute(harvest_sql)

        generate_ods(request, harvest_request)
      end

      private

        def filter_activity_production(activity_production_ids)
          if activity_production_ids.present?
            "AND ap.id IN (#{activity_production_ids.join(',')}) AND target_products.activity_production_id IN (#{activity_production_ids.join(',')})"
          else
            ''
          end
        end

        def filter_harvest_activity_production(activity_production_ids)
          if activity_production_ids.present?
            "AND ap.id IN (#{activity_production_ids.join(',')})"
          else
            ''
          end
        end

        def generate_ods(dataset, harvest_dataset)
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
          headers << :production.tl
          headers << :total_net_surface_area.tl
          headers << Intervention.human_attribute_name(:procedure_name)
          headers << :date.tl
          headers << InterventionTarget.human_attribute_name(:name)
          headers << :cultivation.tl
          headers << :working_area.tl
          headers << :evaluated_input_cost.tl
          headers << :evaluated_tool_cost.tl
          headers << :evaluated_doer_cost.tl
          headers << :evaluated_reception_cost.tl
          headers << :total_cost.tl
          headers << :working_hectare_costs.tl
          headers << :link.tl

          wb.add_worksheet(name: :interventions_costs.tl) do |sheet|
            # add header
            sheet.add_row headers, style: [header_style] * headers.count
            # add lines
            total_inputs_costs = []
            total_tools_costs = []
            total_doers_costs = []
            total_receptions_costs = []
            total_total_costs = []
            dataset.each_with_index do |item, index|
              line = item.to_struct
              intervention_url = "https://#{Ekylibre::Tenant.host}" + backend_intervention_path(line.intervention_id)
              plant_presence = Product.find(line.target_product_id).is_a?(Plant)
              detail = []
              detail_style = []
              detail << line.activity_production_name # column A
              detail_style << row_style
              detail << ((line.activity_production_size.presence && line.activity_production_size_unit.presence) ? line.activity_production_size.to_d.in(line.activity_production_size_unit.to_sym).convert(:hectare).to_d.round(2) : nil)
              detail_style << row_style
              detail << I18n.t(line.procedure_name, scope: 'procedures')
              detail_style << row_style
              detail << Date.parse(line.started_at)
              detail_style << date_style
              detail << line.target_name
              detail_style << row_style
              detail << (plant_presence ? :plant.tl : :land_parcel_name.tl)
              detail_style << row_style
              detail << line.target_working_zone.to_d.round(2)
              detail_style << row_style
              detail << line.inputs_costs.to_d.round(2) # column H
              detail_style << row_style
              total_inputs_costs << line.inputs_costs.to_d.round(2)
              detail << line.tools_costs.to_d.round(2)
              detail_style << row_style
              total_tools_costs << line.tools_costs.to_d.round(2)
              detail << line.doers_costs.to_d.round(2)
              detail_style << row_style
              total_doers_costs << line.doers_costs.to_d.round(2)
              detail << line.receptions_costs.to_d.round(2)
              detail_style << row_style
              total_receptions_costs << line.receptions_costs.to_d.round(2)
              detail << line.total_costs.to_d.round(2)
              detail_style << row_style
              total_total_costs << line.total_costs.to_d.round(2)
              detail << (line.target_working_zone.present? ? (line.total_costs.to_d / line.target_working_zone.to_d).round(2) : nil)
              detail_style << row_style
              detail << line.intervention_number
              detail_style << row_style

              sheet.add_row detail, style: detail_style
              sheet.add_hyperlink location: intervention_url, ref: "N#{index + 2}"
            end
            # add sum formula
            bottom_formula = []
            bottom_formula << :totals.tl
            bottom_formula << ''
            bottom_formula << ''
            bottom_formula << ''
            bottom_formula << ''
            bottom_formula << ''
            bottom_formula << ''
            bottom_formula << total_inputs_costs.compact.sum
            bottom_formula << total_tools_costs.compact.sum
            bottom_formula << total_doers_costs.compact.sum
            bottom_formula << total_receptions_costs.compact.sum
            bottom_formula << total_total_costs.compact.sum
            bottom_formula << ''

            sheet.add_row bottom_formula, style: [formula_style] * headers.count

            # add progress bar on costs
            data_bar = Axlsx::DataBar.new
            sheet.add_conditional_formatting("M2:M#{dataset.count + 1}",
                                             type: :dataBar,
                                             dxfId: legal_ratio_style,
                                             priority: 1,
                                             data_bar: data_bar)

          end

          # Worksheet Productions
          production_dataset = dataset.group_by { |a| a["activity_production_id"]}.deep_symbolize_keys
          production_headers = []
          production_headers << :production.tl
          production_headers << :total_net_surface_area.tl
          production_headers << :working_area.tl
          production_headers << :evaluated_input_cost.tl
          production_headers << :input_cost_per_hectare.tl
          production_headers << :evaluated_tool_cost.tl
          production_headers << :tool_cost_per_hectare.tl
          production_headers << :evaluated_doer_cost.tl
          production_headers << :time_cost_per_hectare.tl
          production_headers << :evaluated_reception_cost.tl
          production_headers << :total_cost.tl
          production_headers << :costs_per_hectare.tl
          production_headers << :objective_costs_per_hectare.tl

          wb.add_worksheet(name: :production_costs.tl) do |sheet|
            sheet.add_row production_headers, style: [header_style] * production_headers.count
            production_dataset.each do |_k, v|
              production_net_surface_area = ((v.first[:activity_production_size].presence && v.first[:activity_production_size_unit].presence) ? v.first[:activity_production_size].to_d.in(v.first[:activity_production_size_unit].to_sym).convert(:hectare).to_d.round(2) : nil)
              cost_target_per_hectare = (v.first[:objectif_cost_per_hectare].presence ? v.first[:objectif_cost_per_hectare].to_d.round(2) : nil)
              production_detail = []
              production_detail << v.first[:activity_production_name]
              production_detail << production_net_surface_area
              production_detail << v.map { |i| i[:target_working_zone].to_d}.reduce(0, :+).round(2)
              production_detail << v.map { |i| i[:inputs_costs].to_d}.reduce(0, :+).round(2)
              production_detail << (v.map { |i| i[:inputs_costs].to_d}.reduce(0, :+).round(2) / production_net_surface_area).round(2)
              production_detail << v.map { |i| i[:tools_costs].to_d}.reduce(0, :+).round(2)
              production_detail << (v.map { |i| i[:tools_costs].to_d}.reduce(0, :+).round(2) / production_net_surface_area).round(2)
              production_detail << v.map { |i| i[:doers_costs].to_d}.reduce(0, :+).round(2)
              production_detail << (v.map { |i| i[:doers_costs].to_d}.reduce(0, :+).round(2) / production_net_surface_area).round(2)
              production_detail << v.map { |i| i[:receptions_costs].to_d}.reduce(0, :+).round(2)
              production_detail << v.map { |i| i[:total_costs].to_d}.reduce(0, :+).round(2)
              production_detail << (v.map { |i| i[:total_costs].to_d}.reduce(0, :+) / production_net_surface_area).round(2)
              production_detail << cost_target_per_hectare
              sheet.add_row production_detail, style: [row_style] * production_headers.count

              # add progress bar on costs
              data_bar = Axlsx::DataBar.new
              sheet.add_conditional_formatting("E2:E#{production_dataset.count + 1}",
                                               type: :dataBar,
                                               dxfId: legal_ratio_style,
                                               priority: 1,
                                               data_bar: data_bar)
              sheet.add_conditional_formatting("G2:G#{production_dataset.count + 1}",
                                               type: :dataBar,
                                               dxfId: legal_ratio_style,
                                               priority: 1,
                                               data_bar: data_bar)
              sheet.add_conditional_formatting("I2:I#{production_dataset.count + 1}",
                                               type: :dataBar,
                                               dxfId: legal_ratio_style,
                                               priority: 1,
                                               data_bar: data_bar)
              sheet.add_conditional_formatting("L2:L#{production_dataset.count + 1}",
                                               type: :dataBar,
                                               dxfId: total_cost_ratio_style,
                                               priority: 2,
                                               data_bar: data_bar)
            end
          end

          harvest_headers = []
          harvest_headers << :production.tl
          harvest_headers << :date.tl
          harvest_headers << InterventionInput.human_attribute_name(:quantity)
          harvest_headers << InterventionInput.human_attribute_name(:quantity_unit)
          harvest_headers << InterventionInput.human_attribute_name(:quantity)
          harvest_headers << InterventionInput.human_attribute_name(:quantity_unit)

          wb.add_worksheet(name: :yield.tl) do |sheet|
            sheet.add_row harvest_headers, style: [header_style] * harvest_headers.count
            harvest_dataset.each do |item|
              line = item.to_struct
              harvest_detail = []
              harvest_detail << line.activity_production_name
              harvest_detail << line.started_at.to_time.strftime("%d/%m/%Y")
              harvest_detail << line.target_quantity_population.to_d.round(2)
              harvest_detail << line.variant_unit_name
              harvest_detail << line.target_quantity_value.to_d.round(2)
              harvest_detail << (line.quantity_unit.presence && Onoma::Unit[line.quantity_unit.to_sym].present? ? Onoma::Unit[line.quantity_unit.to_sym].symbol : nil)
              sheet.add_row harvest_detail, style: [row_style] * harvest_headers.count
            end
          end
          p.to_stream
        end
    end
  end
end
