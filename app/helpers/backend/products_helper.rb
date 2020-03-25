module Backend
  module ProductsHelper
    # Show a chart with working time spent between different activities
    # It can accept :cobbler option to specify inclusion.
    def time_spent_by_activity(resource, options = {})
      campaign = options[:current_campaign]
      return nil if campaign.nil?

      working_periods = InterventionWorkingPeriod
                          .precise_working_periods(options.fetch(:as, :tool), resource)
                          .of_campaign(campaign)
      return nil if working_periods.empty?

      stopped_at = working_periods.reorder(stopped_at: :desc).first.stopped_at.to_date
      started_at = working_periods.reorder(started_at: :asc).first.started_at.to_date
      stopped_at = started_at + 1.day if started_at >= stopped_at

      unit = Nomen::Unit[options.fetch(:time_unit, :hour)]

      series = []
      categories = {}

      date = started_at
      while date < stopped_at
        categories[date.year.to_s + date.month.to_s.rjust(3, '0')] = date.l(format: '%b %Y')
        date = date >> 1
      end

      # data for bar chart times by activities and by month
      Activity.find_each do |activity|
        act_interventions = Intervention::HABTM_Activities
                              .where(intervention_id: working_periods.pluck(:intervention_id), activity_id: activity.id)
                              .reorder(:intervention_started_at)
                              .group_by { |m| m.intervention_started_at.year.to_s + m.intervention_started_at.month.to_s.rjust(3, '0') }

        if act_interventions.any?
          sums = {}
          act_interventions.each do |act_int_by_month|
            sums[act_int_by_month[0].to_i.to_s] = act_int_by_month[1]
                                                    .map{|i| i.intervention_activity_working_duration}
                                                    .compact.sum.to_i
                                                    .in_second.in(unit)
                                                    .round(2).to_f
          end

          series << {
            name: activity.name,
            data: normalize_serie(sums, categories.keys),
            tooltip: { value_suffix: unit.symbol },
            color: activity.color
          }
        end
      end

      # Without activities
      activity_periods = working_periods.without_activity.order(:started_at)
      if activity_periods.any?
        sums = activity_periods.sums_of_periods.sort.each_with_object({}) do |period, hash|
          hash[period.expr.to_i.to_s] = period.sum.to_i.in_second.in(unit).round(2).to_f
          hash
        end
        series << { name: :undefined_activity.tl, data: normalize_serie(sums, categories.keys),
                    tooltip: { value_suffix: unit.symbol }, color: '#777777' }
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

    # A product mini map show shape between born_at if born_at is in the
    # future
    def product_mini_map(product = nil)
      product ||= resource
      unless product.is_a?(Product)
        raise ArgumentError, 'Product expected, got ' + product.inspect
      end
      mini_map(product) do |r|
        { name: r.name, shape: r.shape }
      end
    end

    def product_info(name, options = {}, &block)
      product ||= resource
      unless product.respond_to?(name)
        options[:value] ||= product.send(name, at: [product.born_at, Time.zone.now].compact.max)
      end
      resource_info(name, options, &block)
    end
  end
end
