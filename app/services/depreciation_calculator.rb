# frozen_string_literal: true

class DepreciationCalculator
  def initialize(financial_year_reference, depreciation_period)
    @fy_reference = financial_year_reference
    @depreciation_period = depreciation_period
  end

  # We base the default start day of the financial year on the day following the reference FinancialYear as
  # it can have an length that is not 1 year
  def financial_year_start_day
    @fy_reference.stopped_on + 1.day
  end

  def depreciation_period(started_on, yearly_percentage)
    months = monthly_periods(started_on, yearly_percentage)

    return months if @depreciation_period == :monthly

    fy_start = financial_year_start_day
    # shift for non leap year before Februar on reference
    # 2020 => 01/03/2020 - 01/01/2020 => 60.days - 1
    # 2019 => 01/03/2019 - 01/01/2019 => 59.days
    fy_shift = if fy_start.month > 2 && Date.leap?(fy_start.year)
                 (fy_start - fy_start.beginning_of_year).days - 1.day
               else
                 (fy_start - fy_start.beginning_of_year).days
               end

    groups = case @depreciation_period
             when :quarterly
               months.group_by { |m_started_on, _m_stopped_on, _| ((Date.leap?(m_started_on.year) && m_started_on.month > 2) ? (m_started_on - fy_shift + 1).beginning_of_quarter : (m_started_on - fy_shift).beginning_of_quarter) }
             when :yearly
               months.group_by { |m_started_on, _m_stopped_on, _| ((Date.leap?(m_started_on.year) && m_started_on.month > 2) ? (m_started_on - fy_shift + 1).year : (m_started_on - fy_shift).year) }
             else
               return nil
             end

    j = groups.map do |_, v|
      first_period_start = v.first.first
      last_period_end = v.last.second
      period_duration = v.sum(&:third)

      [first_period_start, last_period_end, period_duration]
    end
  end

  def monthly_periods(started_on, yearly_percentage)
    return if yearly_percentage == 0

    depreciation_duration = 100 / yearly_percentage.to_f * 360 # in days

    months = []
    current = started_on
    current = current + 1.day if started_on.day === 31
    remaining_days = depreciation_duration
    while remaining_days >= 30
      month_end = current.end_of_month
      month_duration = 30 - current.day + 1
      months << [current, month_end, month_duration]

      current = month_end + 1.day
      remaining_days -= month_duration
    end
    if remaining_days > 0
      months << [current, current + remaining_days.days, remaining_days.to_i]
    end

    months
  end
end
