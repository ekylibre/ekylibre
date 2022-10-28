module Backend
  module Visualizations
    class EconomicMapCellsVisualizationsController < Backend::VisualizationsController
      respond_to :json

      def show
        config = {}
        data = []

        activity_production_ids = params[:activity_production_ids]
        campaigns = params[:campaigns]

        activity_productions = ActivityProduction
        if activity_production_ids
          activity_productions = activity_productions.where(id: activity_production_ids)
        end

        if campaigns && activity_productions.where.not(support_shape: nil).any?

          campaign = Campaign.find(campaigns)

          activity_productions.of_campaign(campaigns).includes(:activity, :cultivable_zone).find_each do |support|
            next unless support.support_shape

            economic_data = ActivityProductionsInterventionsCost.of_activity_production(support)
            interventions_count = economic_data.pluck(:intervention_id).uniq.count
            tool_cost = economic_data.sum(:tools)
            input_cost = economic_data.sum(:inputs)
            time_cost = economic_data.sum(:doers)

            popup_content = []

            # for support

            # popup_content << {label: :campaign.tl, value: view_context.link_to(params[:campaigns.name, backend_campaign_path(params[:campaigns))}
            popup_content << { label: ActivityProduction.human_attribute_name(:net_surface_area), value: support.human_support_shape_area }
            popup_content << { label: ActivityProduction.human_attribute_name(:activity), value: view_context.link_to(support.activity_name, backend_activity_path(support.activity)) }

            popup_content << { label: :costs_per_hectare.tl }
            popup_content << { value: "#{:inputs.tl} : #{input_cost.to_s.to_f.round(2)}" }
            popup_content << { value: "#{:tools.tl} : #{tool_cost.to_s.to_f.round(2)}" }
            popup_content << { value: "#{:times.tl} : #{time_cost.to_s.to_f.round(2)}" }

            surface_unit_name = :hectare

            item = {
              name: support.name,
              shape: support.support_shape,
              shape_color: support.activity.color,
              activity: support.activity.name,
              tool_cost: tool_cost.to_s.to_f.round(2),
              input_cost: input_cost.to_s.to_f.round(2),
              time_cost: time_cost.to_s.to_f.round(2),
              interventions_count: interventions_count,
              popup: { header: true, content: popup_content }
            }
            data << item
          end

          config = view_context.configure_visualization do |v|
            v.serie :main, data
            v.categories :activity, :main
            v.choropleth :interventions_count, :main
            v.choropleth :tool_cost, :main, stop_color: "#00AA00"
            v.choropleth :input_cost, :main, stop_color: "#1122DD"
            v.choropleth :time_cost, :main, stop_color: "#E77000"
          end

        end

        respond_with config
      end
    end
  end
end
