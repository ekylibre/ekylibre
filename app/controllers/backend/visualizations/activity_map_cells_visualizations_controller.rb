module Backend
  module Visualizations
    class ActivityMapCellsVisualizationsController < Backend::VisualizationsController
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
        if campaigns
          aps = activity_productions.where.not(support_shape: nil).of_campaign(campaigns)
        else
          aps = activity_productions.where.not(support_shape: nil)
        end

        if aps.any?
          sensor_data = []
          if Sensor.any?
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
          end

          if CapNeutralArea.any?
            campaign = Campaign.find(campaigns)
            if CapNeutralArea.of_campaign([*campaign.previous].push(campaign)).any?
              cap_neutral_areas = []
              until cap_neutral_areas.any?
                cap_neutral_areas = CapNeutralArea.of_campaign(campaign)
                campaign = campaign.preceding
              end

              cap_neutral_areas_data = cap_neutral_areas.map do |cap_neutral_area|
                next unless cap_neutral_area.shape

                popup_content = []
                if cap_neutral_area.shape_area > 0.0.in_square_meter
                  popup_content << { label: CapLandParcel.human_attribute_name(:net_surface_area), value: cap_neutral_area.human_shape_area }
                end
                popup_content << { label: CapNeutralArea.human_attribute_name(:category), value: MasterCropProductionCapSnaCode.find_by(reference_name: cap_neutral_area.category).translation.send(I18n.locale) }
                popup_content << { label: CapNeutralArea.human_attribute_name(:nature), value: MasterCropProductionCapSnaCode.find_by(reference_name: cap_neutral_area.nature).translation.send(I18n.locale) }
                popup_content << render_to_string(partial: 'cna_popup')

                {
                  name: cap_neutral_area.number,
                  neutral_area_category: MasterCropProductionCapSnaCode.find_by(reference_name: cap_neutral_area.nature).translation.send(I18n.locale),
                  shape: cap_neutral_area.shape,
                  popup: { header: true, content: popup_content }
                }
              end
            end
          end

          aps.includes(:activity, :campaign, :cultivable_zone, :interventions).find_each do |support|
            popup_content = []

            # for support
            # popup_content << {label: :campaign.tl, value: view_context.link_to(params[:campaigns.name, backend_campaign_path(params[:campaigns))}
            popup_content << { label: ActivityProduction.human_attribute_name(:net_surface_area), value: support.human_support_shape_area }
            popup_content << { label: ActivityProduction.human_attribute_name(:activity), value: view_context.link_to(support.activity_name, backend_activity_path(support.activity)) }

            surface_unit_name = :hectare
            interventions = support.interventions.real
            if interventions.any?
              last_intervention = interventions.order(started_at: :desc).first
              popup_content << { label: :last_intervention.tl + " | #{last_intervention.started_at.l}", value: view_context.link_to(last_intervention.name, backend_intervention_path(last_intervention)) }
            end

            # build frequency indicator of spraying (IFT map)
            # IFT activity production
            pfi_activity_production = PfiCampaignsActivitiesIntervention.pfi_value_on_activity_production_campaign(support, campaigns)
            popup_content << { label: :pfi_activity_production.tl, value: view_context.link_to(pfi_activity_production, backend_activity_production_path(support)) }
            popup_content << render_to_string(partial: 'popup', locals: { production: support })

            item = {
              name: support.name,
              shape: support.support_shape,
              shape_color: support.activity.color,
              activity: support.activity.name,
              pfi_activity_production: pfi_activity_production,
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

            if cap_neutral_areas_data.present?
              v.serie :cap_neutral_areas_data, cap_neutral_areas_data
              v.categories :neutral_area_category, :cap_neutral_areas_data, without_ghost_label: true
            end

            v.choropleth :pfi_activity_production, :main, stop_color: "#AA00AA"
            v.categories :activity, :main
          end

        end

        respond_with config
      end
    end
  end
end
