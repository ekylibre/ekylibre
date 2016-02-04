module Backend
  module ActivityProductionsHelper

    def production_chronologies(productions, campaign = nil)
      campaign ||= current_campaign
      return nil if productions.empty?
      dates = (productions.map { |p| p.started_on_for(campaign) } +
               productions.map { |p| p.stopped_on_for(campaign) }).sort
      margin = ((dates.last - dates.first).to_f * 0.07).to_i
      period_started_on = (dates.first - margin).beginning_of_month
      period_stopped_on = (dates.last + margin).end_of_month
      duration = (period_stopped_on - period_started_on).to_f
      grades = []
      on = period_started_on.dup
      finish = period_stopped_on.beginning_of_month - 1.month
      while on < finish
        grades << on # if grades.empty? || grades.last.year != on.year
        on += 1.month
      end
      render 'backend/shared/production_chronologies', productions: productions,
             campaign: campaign, grades: grades, duration: duration,
             period_started_on: period_started_on
    end

  end
end
