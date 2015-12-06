module Backend
  module ProductsHelper
    # Show a chart with working time spent between different activities
    # It can accept :cobbler option to specify inclusion.
    def time_spent_by_activity(resource, options = {})
      working_periods = InterventionWorkingPeriod.of_campaign(current_campaign).with_generic_cast(:tool, resource)
      return nil unless current_campaign && working_periods.any?
      started_at = working_periods.reorder(started_at: :asc).first.started_at.to_date
      stopped_at = working_periods.reorder(stopped_at: :desc).first.stopped_at.to_date
      duration = working_periods.sum(:duration)

      unit = Nomen::Unit[options[:time_unit] || :hour]

      series = []
      categories = {}

      date = started_at
      stopped_at = started_at + 1 if started_at >= stopped_at
      while date < stopped_at
        categories[date.year.to_s + date.month.to_s.rjust(3, '0')] = date.l(format: '%b %Y')
        date = date >> 1
      end

      # data for bar chart times by activities and by month
      current_campaign.activities.find_each do |activity|
        activity_periods = working_periods.of_activities(activity).order(:started_at)
        if activity_periods.any?
          sums = activity_periods.sums_of_periods.sort.inject({}) do |hash, period|
            hash[period.expr.to_i.to_s] = period.sum.to_i.in_second.in(unit).round(2).to_f
            hash
          end
          series << { name: activity.name, data: normalize_serie(sums, categories.keys),
                      tooltip: { value_suffix: unit.symbol } }
        end
      end

      if series.any?
        html = column_highcharts(series, y_axis: { title: { text: :duration.tl }, stack_labels: { enabled: true, format: "{total} #{unit.symbol}" }, labels: { format: "{value} #{unit.symbol}" } }, x_axis: { categories: categories.values }, legend: true, plot_options: { column: { stacking: 'normal' } })
        if options[:cobbler]
          options[:cobbler].cobble(:time_spent_by_activity) do
            html
          end
        else
          return html
        end
      end
    end
  end
end
