module Backend
  module ProductsHelper
    # Show a chart with working time spent between different activities
    # It can accept :cobbler option to specify inclusion.

    def time_spent_by_activity(resource, options = {})
      working_periods = InterventionWorkingPeriod.with_intervention_parameter(options[:as] || :tool, resource)
      working_periods = working_periods.of_campaign(current_campaign) if options[:current_campaign]
      return nil unless current_campaign && working_periods.any?

      unit = Nomen::Unit[options[:time_unit] || :hour]

      series = []
      activities = []

      # data for bar chart times by activities and by month
      Activity.find_each do |activity|
        activity_periods = working_periods.of_activities(activity)
        if activity_periods.any?
          activities << activity.name
          series << { name: activity.name, y: (activity_periods.sum(:duration) / 3600), tooltip: { value_suffix: unit.symbol }, color: activity.color }
        end
      end

      # Without activities
      activity_periods = working_periods.without_activity
      if activity_periods.any?
        activities << :undefined_activity.tl
        series << { name: :undefined_activity.tl, y: (activity_periods.sum(:duration) / 3600), tooltip: { value_suffix: unit.symbol }, color: '#777777' }
      end
      return unless series.any?

      html = column_highcharts([{ name: 'Activities', data: series }], chart: { type: 'column' }, y_axis: { title: { text: :duration.tl } }, x_axis: { type: 'category' }, legend: true, plot_options: { series: { borderWidth: 0, dataLabels: { enabled: true, format: "{point.y} #{unit.symbol}" } } })
      return html unless options[:cobbler]

      options[:cobbler].cobble(:time_spent_by_activity) do
        html
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
        { name: r.name, shape: r.shape(at: [r.born_at, Time.zone.now].compact.max) }
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
