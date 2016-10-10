module Backend
  module PlantsHelper
    def plants_map
      dimension = :quantity
      data = Plant.of_campaign(current_campaign).collect do |p|
        next unless p.shape

        popup_content = []

        # for all plant
        popup_content << { label: Plant.human_attribute_name(:net_surface_area), value: p.net_surface_area.in_hectare.round(2).l }
        popup_content << { label: Nomen::Variety.find(p.nature.variety).human_name, value: Nomen::Variety.find(p.variety).human_name }

        # for vine plant
        # if p.woodstock_variety
        # popup_content << {label: Nomen::Indicator.find(:woodstock_variety).human_name, value: Nomen::Variety.find(p.woodstock_variety).human_name}
        # end

        # for indicators in list
        indicators = [:tiller_count, :plants_count, :rows_interval, :plants_interval, :rows_orientation]
        indicators.each do |indicator|
          if !p.send(indicator).blank? && (p.send(indicator).to_d > 0.0)
            popup_content << { label: Nomen::Indicator.find(indicator.to_sym).human_name, value: p.send(indicator).l }
          end
        end

        interventions = Intervention.with_generic_cast(:target, p).reorder(:started_at)

        issues = Issue.where(target_id: p.id, target_type: 'Plant').reorder(:observed_at)

        if issues.any?
          popup_content << { label: :issues_count.tl, value: issues.count }
        end

        if issues.any? && (last_issue = issues.last)
          popup_content << { label: :last_issue.tl, value: link_to(last_issue.name, backend_issue_path(last_issue)) }
        end

        # for inspection and marketable_quantity
        inspection = p.inspections.reorder(sampled_at: :desc).first
        if inspection
          activity = inspection.activity
          dimension = activity.unit_preference(current_user)
          popup_content << { label: :last_inspection.tl, value: link_to(inspection.position.to_s, backend_inspection_path(inspection)) }
          if activity.inspection_calibration_scales.any?
            marketable_quantity = inspection.marketable_quantity(dimension).round(2).l(precision: 0)
            popup_content << { label: Inspection.human_attribute_name("marketable_#{dimension}"), value: marketable_quantity }
          end
        end

        # for irrigation management
        water_concentration = []
        water_interventions = Intervention.where(procedure_name: :plant_irrigation).with_generic_cast(:target, p)
        water_interventions.find_each do |intervention|
          intervention.inputs.each do |input|
            if i = input.population / p.shape_area.to_f(:hectare)
              water_concentration << i
            end
          end
        end

        popup_content << render('popup', plant: p)

        {
          name: p.name,
          shape: p.shape,
          marketable_quantity: marketable_quantity.to_s.to_f,
          ready_to_harvest: (p.ready_to_harvest? ? :ready.tl : :not_ready.tl),
          age: (Time.zone.now - p.born_at) / (3600 * 24 * 30),
          plantation_density: (p.plants_count.to_d / p.net_surface_area.in(:square_meter).to_d).to_s.to_f,
          interventions_count: interventions.count,
          issues_count: issues.count,
          watering_concentration: water_concentration.compact.sum.in(:liters).to_s.to_f,
          variety: Nomen::Variety[p.variety].human_name,
          popup: {
            header: true,
            content: popup_content
          }
        }
      end
      crops = Nomen::Unit[:unity].human_name
      water = Nomen::Unit[:liter].human_name
      area = Nomen::Unit[:square_meter].human_name
      plantation_density_unit = "#{crops}/#{area}".downcase
      water_concentration_unit = "#{water}/#{area}".downcase
      visualization(box: { height: '100%' }) do |v|
        v.serie :main, data
        v.bubbles :marketable_quantity, :main
        v.categories :ready_to_harvest, :main, without_ghost_label: true
        v.choropleth :plantation_density, :main, unit: plantation_density_unit
        v.categories :variety, :main
        v.choropleth :watering_concentration, :main, unit: water_concentration_unit, stop_color: '#1122DD', hidden: true
        v.control :zoom
        v.control :scale
        v.control :fullscreen
        v.control :layer_selector
      end
    end
  end
end
