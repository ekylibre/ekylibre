module Backend
  # Helpers for subcriptions and subscription natures
  module SubscriptionsHelper
    # Shows subscriptions count and new subscriptions month by month over the last year
    def subscriptions_chart(nature, options = {})
      series = []

      options[:months] ||= 35
      stopped_on = options[:stopped_on] || Time.zone.today + 11.months
      started_on = options[:started_on] || stopped_on.beginning_of_month - options[:months].months

      categories = []
      date = started_on
      stopped_on = started_on + 1 if started_on >= stopped_on
      while date <= stopped_on
        categories << [date, date.end_of_month, date.l(format: '%b %Y')]
        date = date >> 1
      end

      renewed = []
      stopped = []
      started = []
      all = []
      # Total subscriptions count
      # FIXME Not optimized at all
      categories.each do |(s, e, _l)|
        started << nature.subscriptions.started_between(s, e).count
        renewed << nature.subscriptions.renewed_between(s, e).count
        stopped << nature.subscriptions.stopped_between(s, e).count
        all << nature.subscriptions.between(s, e).select(:swim_lane_uuid).distinct.count
      end

      series << { type: 'column', name: :started.tl, data: started }
      series << { type: 'column', name: :renewed.tl, data: renewed }
      series << { type: 'column', name: :stopped.tl, data: stopped }
      series << { type: 'spline', name: :all.tl, data: all }

      return nil unless options[:blank].is_a?(FalseClass) || series.any?

      html = column_highcharts(series, y_axis: { allow_decimals: false, title: { text: :count.tl } }, x_axis: { categories: categories.map(&:third) }, legend: true)

      return html unless options[:cobbler]

      options[:cobbler].cobble(options[:title] || :subscriptions_in_time) do
        html
      end
      nil
    end
  end
end
