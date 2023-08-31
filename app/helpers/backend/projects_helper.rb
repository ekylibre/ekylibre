module Backend
  module ProjectsHelper
    def project_chronologies(projects)
      return nil if projects.empty?

      projects = projects.includes(:activity)
      dates = (projects.map(&:started_on).compact +
               projects.map(&:stopped_on).compact).sort
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
      render 'backend/shared/project_chronologies', projects: projects,
                                                    grades: grades, duration: duration,
                                                    period_started_on: period_started_on
    end

    def product_chronology_period(started_on, stopped_on, period_started_on, period_duration, background_color, url_options = {}, html_options = {})
      started_on ||= Date.today
      stopped_on ||= Date.today + 12.months
      period_started_on ||= Date.today + 1.month
      period_duration ||= 12
      started_at = (started_on - period_started_on).to_f / period_duration
      width = (stopped_on - started_on).to_f / period_duration

      chronology_period(started_at, width, background_color, url_options, html_options)
    end

    private

      def round(number)
        number.round(2).to_s.to_f
      end
  end
end
