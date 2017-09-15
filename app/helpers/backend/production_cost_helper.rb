module Backend
  module ProductionCostHelper
    def production_cost_charts(activity_production)
      unit = activity_production.activity.size_unit_name.to_sym
      unit ||= :hectare
      unit_item = Nomen::Unit[unit]
      currency = Preference[:currency]
      currency_item = Nomen::Currency[currency]
      global_cost_per_hectare = 0.0
      ordered_interventions = activity_production.interventions.includes(:targets, tools: [:product, :intervention], inputs: :product, doers: [:product, :intervention]).reorder(:started_at)

      data = ordered_interventions.find_each.map do |intervention|
        intervention_costs = [:input, :doer, :tool].map { |role| intervention.cost_per_area(role, unit) || 0.0 }
        cost = round(intervention_costs.sum)
        global_cost_per_hectare += cost

        { name: intervention.name, y: cost, data: intervention_costs.map { |role_cost| round(role_cost) } }
      end

      series = data.map { |series_data| series_data.slice(:name, :data) }
      data_pie = data.map { |pie_data| pie_data.slice(:name, :y) }

      series << pie_style.merge(name: :total.tl, data: data_pie)

      label_measure = "#{currency_item.human_name}/#{unit_item.human_name}"
      symbol_measure = "#{currency_item.symbol}/#{unit_item.symbol}"
      chart_title = "#{:production_cost.tl} : #{global_cost_per_hectare.round(2)} #{label_measure} (#{symbol_measure})"

      column_highcharts(series,
        title: chart_title,
        tooltip: { point_format: "{point.y: 1.2f} #{symbol_measure}" },
        y_axis: {
          title: {text: "#{:cost_per_net_surface_area.tl} (#{symbol_measure})" },
          stack_labels: {
            enabled: true,
            format: "{total} #{symbol_measure}"},
            labels: { format: "{value}" }
          },
        x_axis: { categories: [:input_cost.tl, :doer_cost.tl, :tool_cost.tl] },
        legend: true,
        plot_options: {
          column: { stacking: 'normal' }
        })
    end

    private

    def round(number)
      number.round(2).to_s.to_f
    end

    def pie_style
      {type: 'pie', center: [50, 50], size: 100, show_in_legend: false, data_labels: { enabled: false }}
    end
  end
end
