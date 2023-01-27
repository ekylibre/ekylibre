module PeriodSelectorHelper
  def button_to_previous_period(period_interval, current_period)
    previous_period = current_period - 1.send(period_interval)
    url_params = params.to_unsafe_hash
    url_params[:current_period] = previous_period
    url_params[:current_campaign] = previous_period.year if period_interval == :year
    link_to('', url_params, class: 'btn btn-previous icn icn-only')
  end

  def button_to_today(period_interval)
    link_to("datetime.periods.today".t, { current_period: Date.today, current_period_interval: period_interval }, class: 'btn today-period-btn')
  end

  def displayed_period(period_interval, current_period)
    if period_interval == :day
      current_period.l
    elsif period_interval == :week
      :manual_period.tl(start: current_period.at_beginning_of_week.l, finish: current_period.at_end_of_week.l)
    elsif period_interval == :month
      current_period.l(format: :short_month)
    else
      current_period.year.to_s
    end
  end

  def button_to_next_period(period_interval, current_period)
    next_period = current_period + 1.send(period_interval)
    url_params = params.to_unsafe_hash
    url_params[:current_period] = next_period
    url_params[:current_campaign] = next_period.year if period_interval == :year
    link_to('', url_params, class: 'btn btn-next icn icn-only')
  end

  def dropdown_to_current_period(period_interval, current_period, intervals)
    displayed_period = displayed_period(period_interval, current_period)
    button_group do
      content_tag(:button, nil, { class: "btn btn-with-intervals period #{period_interval}", "data-toggle": "dropdown" }) do
        content_tag(:span, displayed_period) + content_tag(:span, nil, class: 'caret')
      end +
      content_tag(:ul, nil, class: "dropdown-menu interval-menu") do
        intervals.map do |interval|
          content_tag(:li, nil, class:  "") do
            classes = 'period-interval '
            classes << 'active' if period_interval == interval
            link_to("datetime.periods.#{interval}".t, { current_period_interval: interval, current_campaign: current_period.year }, class: classes)
          end
        end.join.html_safe
      end
    end
  end

  def button_to_current_period(period_interval, current_period)
    displayed_period = displayed_period(period_interval, current_period)
    url_params = {}
    if period_interval == :year
      url_params = { controller: '/backend/campaigns', action: :show, id: current_campaign }
    end
    link_to(displayed_period, url_params, class: "btn period #{period_interval}")
  end

  def main_period_selector(*intervals)
    content_for(:heading_toolbar) do
      period_selector(*intervals)
    end
  end

  def period_selector(*intervals)
    options = intervals.extract_options!
    current_period = current_user.current_period.to_date
    current_interval = current_user.current_period_interval.to_sym
    current_user.current_campaign = Campaign.find_or_create_by!(harvest_year: current_period.year)

    default_intervals = %i[day week month year]
    intervals = default_intervals if intervals.empty?
    intervals &= default_intervals
    current_interval = intervals.last unless intervals.include?(current_interval)
    render 'backend/shared/period_selector', current_period: current_period, intervals: intervals, period_interval: current_interval
  end
end
