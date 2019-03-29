module Backend
  module ActivityProductionsHelper
    def production_chronologies(productions, campaign = nil)
      campaign ||= current_campaign
      return nil if productions.empty?
      productions = productions.includes(:activity)
      dates = (productions.map { |p| p.started_on_for(campaign) } +
               productions.map { |p| p.stopped_on_for(campaign) }).sort
      margin = ((dates.last - dates.first).to_f * 0.07).to_i
      period_started_on = (dates.first - margin).beginning_of_month
      period_stopped_on = (dates.last + margin).end_of_month
      duration = (period_stopped_on - period_started_on).to_f
      grades = []
      on = period_started_on.dup
      finish = period_stopped_on.beginning_of_month + 1.month
      while on < finish
        grades << on # if grades.empty? || grades.last.year != on.year
        on += 1.month
      end
      render 'backend/shared/production_chronologies', productions: productions,
                                                       campaign: campaign, grades: grades, duration: duration,
                                                       period_started_on: period_started_on
    end

    def product_chronology_period(started_on, stopped_on, period_started_on, period_duration, background_color, url_options = {}, html_options = {})
      started_at = (started_on - period_started_on).to_f / period_duration
      width = (stopped_on - started_on).to_f / period_duration

      chronology_period(started_at, width, background_color, url_options, html_options)
    end

    def interventions_chronology_icons(interventions_list, period_started_on, duration, html_options = {})
      code = ''
      interventions_list.each do |week_number, interventions|
        html_options[:url] = nil
        now = Date.today
        title = ''
        marked_date = nil

        interventions.each do |intervention|
          html_options[:url] = backend_intervention_path(intervention)
          marked_date = intervention.started_at.to_date
          title += '- ' + intervention.name + "\n"
        end

        if interventions.count > 1
          week_begin_date = Date.commercial(current_campaign.harvest_year, week_number, 1)
          html_options[:url] = backend_interventions_path(current_period: week_begin_date.to_s, current_period_interval: 'week')
          marked_date = week_begin_date
        end

        intervention_icon = marked_date > now ? 'clock' : 'check'
        positioned_at = (marked_date - period_started_on).to_f / duration

        code += chronology_period_icon(positioned_at, intervention_icon, html_options)
      end

      code.html_safe
    end

    def production_cost_charts(activity_production)
      unit = activity_production.activity.size_unit_name.to_sym
      unit ||= :hectare
      unit_item = Nomen::Unit[unit]
      currency = Preference[:currency]
      currency_item = Nomen::Currency[currency]
      global_cost_per_hectare = 0.0
      ordered_interventions = activity_production.interventions.includes(:targets, tools: %i[product intervention], inputs: :product, doers: %i[product intervention]).reorder(:started_at)

      data = ordered_interventions.find_each.map do |intervention|
        intervention_costs = %i[input doer tool].map { |role| intervention.cost_per_area(role, unit) || 0.0 }
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
                          title: { text: "#{:cost_per_net_surface_area.tl} (#{symbol_measure})" },
                          stack_labels: {
                            enabled: true,
                            format: "{total} #{symbol_measure}"
                          },
                          labels: { format: '{value}' }
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
      { type: 'pie', center: [50, 50], size: 100, show_in_legend: false, data_labels: { enabled: false } }
    end
  end
end
