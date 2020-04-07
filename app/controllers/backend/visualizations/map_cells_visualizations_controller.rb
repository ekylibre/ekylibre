module Backend
  module Visualizations
    class MapCellsVisualizationsController < Backend::VisualizationsController
      respond_to :json

      def show
        config = {}
        data = []

        visualization_face = params[:visualization]
        activity_production_ids = params[:activity_production_ids]
        campaigns = params[:campaigns]

        activity_productions = ActivityProduction
        if activity_production_ids
          activity_productions = activity_productions.where(id: activity_production_ids)
        end

        if campaigns && activity_productions.where.not(support_shape: nil).any?

          sensor_data = []
          Sensor.find_each.group_by(&:model_euid).each do |model, sensors|
            items = sensors.map do |sensor|
              next unless sensor.analyses.last && sensor.analyses.last.geolocation
              analysis = sensor.analyses.last
              popup_lines = analysis.items.map do |item|
                next unless item.value.respond_to? :l
                { label: item.human_indicator_name, content: item.value.l }
              end

              battery = sensor.battery_level
              popup_lines << { label: sensor.human_attribute_name(:battery_level), content: battery.to_s } if battery.present?
              transmission = sensor.last_transmission_at
              popup_lines << { label: sensor.human_attribute_name(:last_transmission_at), content: transmission.localize } if transmission.present?

              bottom_line = ''
              bottom_line << "<span>#{view_context.link_to(:see_more_details.tl, sensor.partner_url)}</span>" if sensor.partner_url.present?
              bottom_line << "<i class='icon icon-battery-alert' style='color: red;'></i>" if sensor.alert_on? 'battery_life'
              bottom_line << "<i class='icon icon-portable-wifi-off' style='color: red;'></i>" if sensor.alert_on? 'lost_connection'
              popup_lines << ("<div style='display: flex; justify-content: space-between'>" + bottom_line + '</div>').html_safe
              header_content = "<span class='sensor-name'>#{sensor.name}</span>#{view_context.lights(sensor.alert_status)}".html_safe
              {
                sensor_id: sensor.id,
                name: sensor.name,
                shape: analysis.geolocation,
                shape_color: '#' + Digest::MD5.hexdigest(model)[0, 6].upcase,
                group: model.camelize,
                popup: { header: header_content, content: popup_lines }
              }
            end

            sensor_data += (items || []).compact
          end

          activity_productions.of_campaign(campaigns).includes(:activity, :campaign, :cultivable_zone, interventions: [:outputs, :participations, tools: :product, inputs: :product]).find_each do |support|
            next unless support.support_shape
            popup_content = []

            # for support

            # popup_content << {label: :campaign.tl, value: view_context.link_to(params[:campaigns.name, backend_campaign_path(params[:campaigns))}
            popup_content << { label: ActivityProduction.human_attribute_name(:net_surface_area), value: support.human_support_shape_area }
            popup_content << { label: ActivityProduction.human_attribute_name(:activity), value: view_context.link_to(support.activity_name, backend_activity_path(support.activity)) }
            if (support_input_cost = support.input_cost) && support_input_cost.to_d > 0.0
              popup_content << { label: :costs_per_hectare.tl }
              popup_content << { value: "#{:inputs.tl} : #{support_input_cost.to_s.to_f.round(2)}" }
            end
            if (support_tool_cost = support.tool_cost) && support_tool_cost.to_d > 0.0
              popup_content << { value: "#{:tools.tl} : #{support_tool_cost.to_s.to_f.round(2)}" }
            end
            if (support_time_cost = support.time_cost) && support_time_cost.to_d > 0.0
              popup_content << { value: "#{:times.tl} : #{support_time_cost.to_s.to_f.round(2)}" }
            end

            # nitrogen_concentration = support.soil_enrichment_indicator_content_per_area(:nitrogen_concentration)
            # phosphorus_concentration = support.soil_enrichment_indicator_content_per_area(:phosphorus_concentration)
            # potassium_concentration = support.soil_enrichment_indicator_content_per_area(:potassium_concentration)

            # TODO: refactor
            # if nitrogen_concentration
            #  popup_content << {label: :item_concentration_per_hectare.tl}
            #  symbol = Nomen::ChemicalElement[:nitrogen].symbol
            #  popup_content << {value: "#{symbol} : #{nitrogen_concentration.in(:unity_per_hectare).round(2).l}"}
            # end

            # if phosphorus_concentration
            #  symbol = Nomen::ChemicalElement[:phosphorus].symbol
            #  popup_content << {value: "#{symbol} : #{phosphorus_concentration.in(:unity_per_hectare).round(2).l}"}
            # end

            # if potassium_concentration
            #  symbol = Nomen::ChemicalElement[:potassium].symbol
            #  popup_content << {value: "#{symbol} : #{potassium_concentration.in(:unity_per_hectare).round(2).l}"}
            # end

            # TODO: refactor
            # measure_unit = "#{mass_unit.to_s}_per_#{surface_unit.to_s}"
            # yield_symbol = Nomen::Unit[measure_unit.to_sym]
            surface_unit_name = :hectare

            # case fodder (hay, grass) in ton per hectare
            if support.usage == 'fodder' || support.usage == 'fiber'
              label = :grass_yield
              grass_yield = support.fodder_yield
              popup_content << { label: label.tl, value: grass_yield.round(2).l }

            # case grain in quintal per hectare
            elsif support.usage == 'grain' || support.usage == 'seed'
              label = :grain_yield
              grain_yield = support.grains_yield
              popup_content << { label: label.tl, value: grain_yield.round(2).l }

            # case vegetable
            elsif support.usage == 'vegetable'
              label = :vegetable_yield
              vegetable_yield = support.vegetable_yield
              popup_content << { label: label.tl, value: vegetable_yield.round(2).l }

            # grappe
            elsif support.usage == 'fruit' || support.usage == 'grappe'
              label = :fruit_yield
              fruit_yield = support.fruit_yield
              popup_content << { label: label.tl, value: fruit_yield.round(2).l }
            end

            # if support.net_surface_area
            #  popup_content << {label: CultivableZone.human_attribute_name(:net_surface_area), value: support.net_surface_area.in_hectare.round(2).l}
            # end

            # compute pfi parcel ratio from pfi treatment ratios
            # popup_content << { label: :pfi_parcel_ratio.tl, value: support.pfi_parcel_ratio.round(2) }

            interventions = support.interventions.real
            if interventions.any?
              spent_time = interventions.sum(:working_duration)
              popup_content << { label: :interventions_count.tl, value: "#{interventions.count} #{:during.tl.downcase!} #{:x_hours.tl(count: (spent_time / 3600).round(2))}" }

              last_intervention = interventions.order(started_at: :desc).first
              popup_content << { label: :last_intervention.tl, value: view_context.link_to(last_intervention.name, backend_intervention_path(last_intervention)) }
            end

            # build frequency indicator of spraying (IFT map)

            popup_content << render_to_string(partial: 'popup', locals: { production: support })

            item = {
              name: support.name,
              shape: support.support_shape,
              shape_color: support.activity.color,
              activity: support.activity.name,
              tool_cost: support.tool_cost.to_s.to_f.round(2),
              input_cost: support.input_cost.to_s.to_f.round(2),
              time_cost: support.time_cost.to_s.to_f.round(2),
              # nitrogen_concentration:   nitrogen_concentration.to_s.to_f.round(2),
              # phosphorus_concentration: phosphorus_concentration.to_s.to_f.round(2),
              # potassium_concentration:  potassium_concentration.to_s.to_f.round(2),
              interventions_count: interventions.count,
              # pfi_parcel_ratio:  support.pfi_parcel_ratio,
              grain_yield: grain_yield.to_s.to_f.round(2),
              grass_yield: grass_yield.to_s.to_f.round(2),
              vegetable_yield: vegetable_yield.to_s.to_f.round(2),
              fruit_yield: fruit_yield.to_s.to_f.round(2),
              popup: { header: true, content: popup_content }
            }
            data << item
          end

          config = view_context.configure_visualization do |v|
            v.serie :main, data

            if sensor_data.present?
              v.serie :sensor_data, sensor_data
              v.point_group :sensors, :sensor_data
            end

            if visualization_face == 'nitrogen_footprint'
              v.choropleth :interventions_count, :main
              # v.choropleth :nitrogen_concentration, :main, stop_color: "#777777"
              # v.choropleth :phosphorus_concentration, :main, stop_color: "#11BB99"
              # v.choropleth :potassium_concentration, :main, stop_color: "#AA00AA"
            elsif visualization_face == 'grain_yield'
              v.choropleth :grain_yield, :main, stop_color: '#AA00AA'
              v.choropleth :grass_yield, :main, stop_color: '#00AA00'
              v.choropleth :vegetable_yield, :main, stop_color: '#11BB99'
              v.choropleth :fruit_yield, :main, stop_color: '#1122DD'
              # v.choropleth :pfi_parcel_ratio, :main, stop_color: '#E77000'
            else
              v.choropleth :tool_cost, :main, stop_color: '#00AA00'
              v.choropleth :input_cost, :main, stop_color: '#1122DD'
              v.choropleth :time_cost, :main, stop_color: '#E77000'
            end
            v.categories :activity, :main
          end

        end

        respond_with config
      end
    end
  end
end
