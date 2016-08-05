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
      finish = period_stopped_on.beginning_of_month + 1.month
      while on < finish
        grades << on # if grades.empty? || grades.last.year != on.year
        on += 1.month
      end
      render 'backend/shared/production_chronologies', productions: productions,
                                                       campaign: campaign, grades: grades, duration: duration,
                                                       period_started_on: period_started_on
    end

    def product_chronology_period(production, campaign, period_started_on, duration, url_options = {}, html_options = {})
      started_at = (production.started_on_for(campaign) - period_started_on).to_f / duration
      width = (production.stopped_on_for(campaign) - production.started_on_for(campaign)).to_f / duration

      chronology_period(started_at, width, production.color, url_options, html_options)
    end

    def interventions_chronology_icons(interventions_list, period_started_on, duration, html_options = {})
      code = ''
      interventions_list.each do |week_number, interventions|
        now = Date.today
        title = ''
        marked_date = nil

        interventions.each do |intervention|
          marked_date = intervention.started_at.to_date
          title += '- ' + intervention.name + "\n"
        end

        marked_date = Date.commercial(now.cwyear, week_number, 1) if interventions.count > 1
        intervention_icon = marked_date > now ? 'clock' : 'check'
        positioned_at = (marked_date - period_started_on).to_f / duration

        code += chronology_period_icon(positioned_at, intervention_icon, html_options)
      end

      code.html_safe
    end
  end
end
