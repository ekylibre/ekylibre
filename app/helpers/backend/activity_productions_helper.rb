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

    def product_chronology_period(started_on, stopped_on, period_started_on, period_duration, background_color, url_options = {}, html_options = {})
      started_at = (started_on - period_started_on).to_f / period_duration
      width = (stopped_on - started_on).to_f / period_duration

      chronology_period(started_at, width, background_color, url_options, html_options)
    end

    def interventions_chronology_icons(interventions_list, period_started_on, duration, html_options = {})
      code = ''
      interventions_list.each do |week_number, interventions|
        html_options[:url] = nil
        now = Date.today
        title = ''
        marked_date = nil

        interventions.each do |intervention|
          html_options[:url] = backend_intervention_path(intervention)
          marked_date = intervention.started_at.to_date
          title += '- ' + intervention.name + "\n"
        end

        if interventions.count > 1
          week_begin_date = Date.commercial(current_campaign.harvest_year, week_number, 1)
          html_options[:url] = backend_interventions_path(current_period: week_begin_date.to_s, current_period_interval: 'week')
          marked_date = week_begin_date
        end

        intervention_icon = marked_date > now ? 'clock' : 'check'
        positioned_at = (marked_date - period_started_on).to_f / duration

        code += chronology_period_icon(positioned_at, intervention_icon, html_options)
      end

      code.html_safe
    end
  end
end
