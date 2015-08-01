class Backend::Cells::CalendarCellsController < Backend::Cells::BaseController

  def show
    started_on = (params[:started_on] ? Time.new(*params[:started_on].split("-")) : Time.now)
    @events = Event.between(started_on.beginning_of_month, started_on.end_of_month).includes(participations: [:participant])
    if request.xhr? and params[:started_on]
      render partial: "month"
    end
  end

end
