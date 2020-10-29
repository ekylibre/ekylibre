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
    fy_shift = (fy_start - fy_start.beginning_of_year).days

    groups = case @depreciation_period
             when :quarterly
               months.group_by do |m|
                 shifted = m.started_on - fy_shift
                 [shifted.year, shifted.month % 3]
               end
             when :yearly
               months.group_by { |m_started_on, _, _| (m_started_on - fy_shift).year }
             else
               return nil
             end

    groups.map do |_, v|
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
      months << [current, current + remaining_days.days, remaining_days]
    end

    months
  end
end