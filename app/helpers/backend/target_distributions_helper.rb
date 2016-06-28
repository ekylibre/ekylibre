module Backend
  module TargetDistributionsHelper
    def target_distributions_chronologies(distributions, _product)
      return nil if distributions.empty?
      dates = (distributions.map(&:started_on) +
          distributions.map(&:stopped_on)).sort
      margin = ((dates.last - dates.first).to_f * 0.07).to_i
      period_started_on = dates.first.beginning_of_month
      period_stopped_on = dates.last.end_of_month
      duration = (period_stopped_on - period_started_on).to_f
      grades = []
      on = period_started_on.dup
      finish = period_stopped_on.beginning_of_month - 1.month
      while on < finish
        grades << on # if grades.empty? || grades.last.year != on.year
        on += 1.month
      end
      render 'backend/shared/distribution_chronologies', distributions: distributions,
                                                         grades: grades, duration: duration,
                                                         period_started_on: period_started_on
    end
  end
end
