class Backend::Cells::CalendarCellsController < Backend::Cells::BaseController
  def show
    started_on = (params[:started_on] ? Time.new(*params[:started_on].split('-')) : Time.zone.now)
    @events = Event.between(started_on.beginning_of_month, started_on.end_of_month).includes(participations: [:participant])
    render partial: 'month' if request.xhr? && params[:started_on]
  end
end
